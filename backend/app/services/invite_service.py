"""
Invite service — create / list / accept / revoke invites.

Tokens are generated with `secrets.token_urlsafe` and stored as SHA-256
hashes. The raw token is shown only once to the admin (email link or
copy-link dialog when SMTP is disabled).
"""
from __future__ import annotations

import hashlib
import logging
import secrets
import uuid
from datetime import datetime, timedelta, timezone
from typing import List, Optional, Tuple

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.core.security import get_password_hash
from app.models.invite import Invite
from app.models.user import User, UserRole


logger = logging.getLogger(__name__)

INVITE_TTL_DAYS = 7
TOKEN_NBYTES = 32  # 32 bytes -> ~43 url-safe chars


def _hash_token(raw: str) -> str:
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def _build_invite_link(raw_token: str) -> str:
    base = get_settings().FRONTEND_URL.rstrip("/")
    return f"{base}/accept-invite?token={raw_token}"


class InviteService:
    def __init__(self, tenant_id: str, actor_user_id: Optional[str] = None):
        self.tenant_id = tenant_id
        self.actor_user_id = actor_user_id

    async def create(
        self,
        db: AsyncSession,
        *,
        email: str,
        role: str,
        group_id: Optional[str] = None,
    ) -> Tuple[Invite, str]:
        """Return (invite_row, raw_token). Raw token is NOT stored."""
        raw_token = secrets.token_urlsafe(TOKEN_NBYTES)
        invite = Invite(
            id=str(uuid.uuid4()),
            tenant_id=self.tenant_id,
            email=email.lower().strip(),
            role=role,
            token_hash=_hash_token(raw_token),
            expires_at=datetime.utcnow() + timedelta(days=INVITE_TTL_DAYS),
            created_by=self.actor_user_id,
            group_id=group_id,
        )
        db.add(invite)
        await db.flush()
        return invite, raw_token

    async def list_pending(self, db: AsyncSession) -> List[Invite]:
        stmt = (
            select(Invite)
            .where(
                Invite.tenant_id == self.tenant_id,
                Invite.used_at.is_(None),
                Invite.expires_at > datetime.utcnow(),
            )
            .order_by(Invite.created_at.desc())
        )
        return list((await db.execute(stmt)).scalars().all())

    async def revoke(self, db: AsyncSession, invite_id: str) -> bool:
        stmt = select(Invite).where(
            Invite.id == invite_id,
            Invite.tenant_id == self.tenant_id,
        )
        invite = (await db.execute(stmt)).scalar_one_or_none()
        if invite is None:
            return False
        await db.delete(invite)
        await db.flush()
        return True

    async def resend(
        self,
        db: AsyncSession,
        invite_id: str,
    ) -> Tuple[Optional[Invite], Optional[str]]:
        """Mint a new token + expiry; invalidate the old token by overwriting."""
        stmt = select(Invite).where(
            Invite.id == invite_id,
            Invite.tenant_id == self.tenant_id,
            Invite.used_at.is_(None),
        )
        invite = (await db.execute(stmt)).scalar_one_or_none()
        if invite is None:
            return None, None
        new_raw = secrets.token_urlsafe(TOKEN_NBYTES)
        invite.token_hash = _hash_token(new_raw)
        invite.expires_at = datetime.utcnow() + timedelta(days=INVITE_TTL_DAYS)
        await db.flush()
        return invite, new_raw

    # ----- Accept (public, not tenant-scoped by instance) -----

    @staticmethod
    async def accept(
        db: AsyncSession,
        *,
        token: str,
        full_name: str,
        password: str,
    ) -> Tuple[Optional[User], Optional[str]]:
        """Return (user, error_message). Success => user not-None, error None."""
        token_hash = _hash_token(token)
        stmt = select(Invite).where(Invite.token_hash == token_hash)
        invite = (await db.execute(stmt)).scalar_one_or_none()
        if invite is None:
            return None, "Invalid or unknown invite token."
        if invite.used_at is not None:
            return None, "This invite has already been used."
        now = datetime.utcnow()
        # expires_at may be timezone-aware — compare in a tz-safe way
        expires = invite.expires_at
        if expires.tzinfo is not None:
            expires = expires.replace(tzinfo=None)
        if expires < now:
            return None, "This invite has expired. Ask your admin to resend it."

        # Check no existing user with same email in the tenant
        existing = await db.scalar(
            select(User).where(
                User.tenant_id == invite.tenant_id,
                User.email == invite.email,
            )
        )
        if existing is not None:
            return None, "An account already exists for this email in the tenant."

        # Create the user
        try:
            role_enum = UserRole(invite.role)
        except ValueError:
            role_enum = UserRole.ANALYST

        user = User(
            id=str(uuid.uuid4()),
            tenant_id=invite.tenant_id,
            email=invite.email,
            password_hash=get_password_hash(password),
            full_name=full_name,
            role=role_enum,
            is_active=True,
            is_approved=True,
        )
        db.add(user)

        # Mark invite used
        invite.used_at = now
        await db.flush()

        return user, None


def build_invite_link(raw_token: str) -> str:
    """Public helper used by the endpoint to construct invite URLs."""
    return _build_invite_link(raw_token)
