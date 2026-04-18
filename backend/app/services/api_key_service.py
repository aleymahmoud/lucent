"""
API key service — create / list / revoke / authenticate personal keys.

Keys are `lucent_<32 url-safe chars>`. Stored as SHA-256 hashes. Shown
exactly once at creation.
"""
from __future__ import annotations

import hashlib
import logging
import secrets
import uuid
from datetime import datetime
from typing import List, Optional, Tuple

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.api_key import ApiKey
from app.models.user import User


logger = logging.getLogger(__name__)

KEY_PREFIX = "lucent_"
RANDOM_BYTES = 24     # -> ~32 url-safe chars


def _hash(raw: str) -> str:
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def _generate_raw() -> str:
    return f"{KEY_PREFIX}{secrets.token_urlsafe(RANDOM_BYTES)}"


async def create_key(
    db: AsyncSession,
    *,
    user: User,
    name: str,
    scopes: List[str],
) -> Tuple[ApiKey, str]:
    """Create a new key for `user`. Returns (row, raw_key). raw_key is shown once."""
    raw = _generate_raw()
    row = ApiKey(
        id=str(uuid.uuid4()),
        user_id=user.id,
        tenant_id=user.tenant_id,
        name=name,
        key_hash=_hash(raw),
        key_prefix=raw[:12],  # "lucent_XXXXX"
        scopes=list(scopes),
    )
    db.add(row)
    await db.flush()
    return row, raw


async def list_for_user(db: AsyncSession, user: User) -> List[ApiKey]:
    stmt = (
        select(ApiKey)
        .where(ApiKey.user_id == user.id)
        .order_by(ApiKey.created_at.desc())
    )
    return list((await db.execute(stmt)).scalars().all())


async def revoke(db: AsyncSession, user: User, key_id: str) -> bool:
    stmt = select(ApiKey).where(
        ApiKey.id == key_id,
        ApiKey.user_id == user.id,
    )
    row = (await db.execute(stmt)).scalar_one_or_none()
    if row is None:
        return False
    row.revoked_at = datetime.utcnow()
    await db.flush()
    return True


async def authenticate(db: AsyncSession, raw_key: str) -> Optional[User]:
    """
    Resolve a raw API key to its owning user (or None on no match / revoked).
    Updates last_used_at on success.
    """
    if not raw_key or not raw_key.startswith(KEY_PREFIX):
        return None
    h = _hash(raw_key)
    stmt = (
        select(ApiKey, User)
        .join(User, User.id == ApiKey.user_id)
        .where(
            ApiKey.key_hash == h,
            ApiKey.revoked_at.is_(None),
        )
    )
    row = (await db.execute(stmt)).first()
    if row is None:
        return None
    api_key, user = row
    if not user.is_active:
        return None
    # Best-effort last_used_at update
    try:
        api_key.last_used_at = datetime.utcnow()
        await db.flush()
    except Exception as exc:
        logger.warning(f"Failed to update api_key.last_used_at: {exc}")
    return user
