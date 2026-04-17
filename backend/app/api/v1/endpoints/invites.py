"""
Invite endpoints:
  - POST   /users/invite         — tenant admin creates invite (emails if SMTP)
  - GET    /users/invites        — list pending invites
  - DELETE /users/invites/{id}   — revoke an invite
  - POST   /users/invites/{id}/resend  — mint new token + reset expiry
  - POST   /accept-invite         — public, exchange token for user + session

Mounted under two prefixes in api.py:
  - /users/invite*, /users/invites*  via `users_router_extras` (tenant admin)
  - /accept-invite                    via `public_router` (no auth)
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_tenant_admin, get_db
from app.core.security import create_access_token
from app.models.user import User
from app.schemas.invite import (
    AcceptInviteRequest,
    InviteCreateRequest,
    InviteCreatedResponse,
    InviteListItem,
    InviteListResponse,
)
from app.services.invite_service import InviteService, build_invite_link
from app.services.mailer import send_invite


# ============================================
# Tenant-admin router (mounted at /users)
# ============================================

router = APIRouter()


@router.post("/invite", response_model=InviteCreatedResponse)
async def create_invite(
    body: InviteCreateRequest,
    current_user: User = Depends(get_current_tenant_admin),
    db: AsyncSession = Depends(get_db),
) -> InviteCreatedResponse:
    """Create an invite; email the invitee if SMTP is configured."""
    service = InviteService(current_user.tenant_id, actor_user_id=current_user.id)
    invite, raw_token = await service.create(
        db,
        email=str(body.email),
        role=body.role,
        group_id=body.group_id,
    )
    await db.commit()
    invite_link = build_invite_link(raw_token)

    # Best-effort email
    sent = await send_invite(to_email=str(body.email), invite_link=invite_link,
                             inviter_email=current_user.email)

    return InviteCreatedResponse(
        id=invite.id,
        email=invite.email,
        role=invite.role,
        expires_at=invite.expires_at,
        # Only expose the raw link when email wasn't sent — admin needs to share manually
        invite_link=None if sent else invite_link,
    )


@router.get("/invites", response_model=InviteListResponse)
async def list_invites(
    current_user: User = Depends(get_current_tenant_admin),
    db: AsyncSession = Depends(get_db),
) -> InviteListResponse:
    service = InviteService(current_user.tenant_id)
    rows = await service.list_pending(db)

    # Resolve creator emails
    creator_emails: dict[str, str] = {}
    creator_ids = {r.created_by for r in rows if r.created_by}
    if creator_ids:
        creators = (
            await db.execute(
                select(User.id, User.email).where(User.id.in_(list(creator_ids)))
            )
        ).all()
        creator_emails = {uid: em for uid, em in creators}

    return InviteListResponse(
        invites=[
            InviteListItem(
                id=r.id,
                email=r.email,
                role=r.role,
                expires_at=r.expires_at,
                used_at=r.used_at,
                created_at=r.created_at,
                created_by_email=creator_emails.get(r.created_by) if r.created_by else None,
            )
            for r in rows
        ]
    )


@router.delete("/invites/{invite_id}")
async def revoke_invite(
    invite_id: str,
    current_user: User = Depends(get_current_tenant_admin),
    db: AsyncSession = Depends(get_db),
) -> dict:
    service = InviteService(current_user.tenant_id)
    ok = await service.revoke(db, invite_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Invite not found")
    await db.commit()
    return {"revoked": True}


@router.post("/invites/{invite_id}/resend", response_model=InviteCreatedResponse)
async def resend_invite(
    invite_id: str,
    current_user: User = Depends(get_current_tenant_admin),
    db: AsyncSession = Depends(get_db),
) -> InviteCreatedResponse:
    service = InviteService(current_user.tenant_id, actor_user_id=current_user.id)
    invite, raw_token = await service.resend(db, invite_id)
    if invite is None or raw_token is None:
        raise HTTPException(status_code=404, detail="Invite not found or already used")
    await db.commit()

    invite_link = build_invite_link(raw_token)
    sent = await send_invite(to_email=invite.email, invite_link=invite_link,
                             inviter_email=current_user.email)

    return InviteCreatedResponse(
        id=invite.id,
        email=invite.email,
        role=invite.role,
        expires_at=invite.expires_at,
        invite_link=None if sent else invite_link,
    )


# ============================================
# Public router (mounted at root)
# ============================================

public_router = APIRouter()


@public_router.post("/accept-invite")
async def accept_invite(
    body: AcceptInviteRequest,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Exchange a valid invite token for a new user + session tokens."""
    user, error = await InviteService.accept(
        db,
        token=body.token,
        full_name=body.full_name,
        password=body.password,
    )
    if error:
        # 410 Gone is appropriate for expired/used tokens
        code = status.HTTP_410_GONE if "expired" in error or "already been used" in error else status.HTTP_400_BAD_REQUEST
        raise HTTPException(status_code=code, detail=error)

    await db.commit()

    # Issue a login token so the user lands authenticated
    access_token = create_access_token(data={
        "sub": user.id,
        "tenant_id": user.tenant_id,
        "role": user.role.value,
    })

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "email": user.email,
            "full_name": user.full_name,
            "role": user.role.value,
            "tenant_id": user.tenant_id,
        },
    }
