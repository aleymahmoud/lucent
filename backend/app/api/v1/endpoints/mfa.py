"""
MFA endpoints:
  - POST /mfa/enroll         — returns secret + QR + backup codes (plain, once)
  - POST /mfa/verify         — confirm enrolment with a valid TOTP code
  - POST /mfa/disable        — disable MFA (requires password re-confirm)
  - POST /auth/mfa/challenge — complete login when MFA required
"""
from __future__ import annotations

from typing import Optional
from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.core.security import create_access_token, decode_access_token, verify_password
from app.models.user import User
from app.schemas.mfa import (
    MfaChallengeRequest,
    MfaDisableRequest,
    MfaEnrollResponse,
    MfaVerifyRequest,
)
from app.services import mfa_service


router = APIRouter()


class _EnrollState(BaseModel):
    """Pending enrolment held in-memory for the current session."""
    secret: str
    backup_codes_plain: list[str]


# In-memory store keyed by user_id: user must call /enroll then /verify within
# the same process. Acceptable for single-instance dev; production should use
# Redis. Kept simple here to avoid an extra cross-service round-trip.
_pending_enrollments: dict[str, _EnrollState] = {}


@router.post("/enroll", response_model=MfaEnrollResponse)
async def enroll_mfa(
    current_user: User = Depends(get_current_user),
) -> MfaEnrollResponse:
    """Start MFA enrolment. Call /verify next with a TOTP code to activate."""
    if current_user.mfa_enabled:
        raise HTTPException(status_code=400, detail="MFA is already enabled.")
    secret = mfa_service.generate_secret()
    codes_plain = mfa_service.generate_backup_codes()
    _pending_enrollments[current_user.id] = _EnrollState(
        secret=secret, backup_codes_plain=codes_plain
    )
    return MfaEnrollResponse(
        secret=secret,
        qr_uri=mfa_service.qr_uri(secret, current_user.email),
        backup_codes=codes_plain,
    )


@router.post("/verify")
async def verify_enrollment(
    body: MfaVerifyRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Finalise enrolment by submitting a live TOTP code from the authenticator app."""
    pending = _pending_enrollments.get(current_user.id)
    if pending is None:
        raise HTTPException(
            status_code=400,
            detail="No pending enrolment; call /mfa/enroll first.",
        )
    if not mfa_service.verify_totp(pending.secret, body.code):
        raise HTTPException(status_code=400, detail="Invalid code. Try again.")

    # Persist
    current_user.mfa_secret = pending.secret
    current_user.mfa_enabled = True
    current_user.mfa_backup_codes = mfa_service.store_backup_codes(pending.backup_codes_plain)
    await db.commit()
    _pending_enrollments.pop(current_user.id, None)
    return {"enabled": True}


@router.post("/disable")
async def disable_mfa(
    body: MfaDisableRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Turn off MFA. Requires password re-confirmation."""
    if not current_user.mfa_enabled:
        return {"enabled": False}
    if not verify_password(body.password, current_user.password_hash):
        raise HTTPException(status_code=400, detail="Incorrect password.")
    current_user.mfa_secret = None
    current_user.mfa_enabled = False
    current_user.mfa_backup_codes = None
    await db.commit()
    return {"enabled": False}


# ============================================
# Login challenge (public-session intermediate)
# ============================================

challenge_router = APIRouter()


@challenge_router.post("/mfa/challenge")
async def mfa_challenge(
    body: MfaChallengeRequest,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Complete login when the /auth/login step returned require_mfa=true."""
    payload = decode_access_token(body.challenge_token)
    if payload is None or payload.get("type") != "mfa_challenge":
        raise HTTPException(status_code=401, detail="Invalid or expired challenge token.")
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid challenge payload.")

    user = await db.scalar(select(User).where(User.id == user_id))
    if user is None or not user.mfa_enabled or not user.mfa_secret:
        raise HTTPException(status_code=400, detail="MFA is not configured for this account.")

    code = body.code.strip().replace(" ", "")
    matched = False
    # Try TOTP first (6-digit numeric), then backup code (xxxx-xxxx)
    if mfa_service.verify_totp(user.mfa_secret, code):
        matched = True
    else:
        ok, updated = mfa_service.verify_backup_code(user, code)
        if ok:
            user.mfa_backup_codes = updated
            await db.commit()
            matched = True

    if not matched:
        raise HTTPException(status_code=400, detail="Invalid code.")

    # Issue a real access token
    access_token = create_access_token(data={
        "sub": user.id,
        "tenant_id": user.tenant_id,
        "role": user.role.value if hasattr(user.role, "value") else str(user.role),
    })
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "email": user.email,
            "full_name": user.full_name,
            "role": user.role.value if hasattr(user.role, "value") else str(user.role),
            "tenant_id": user.tenant_id,
        },
    }
