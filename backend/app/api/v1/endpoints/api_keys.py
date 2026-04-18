"""
API key endpoints:
  - GET    /api-keys         — list caller's keys
  - POST   /api-keys         — create key, return raw once
  - DELETE /api-keys/{id}    — revoke
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.api_key import (
    ApiKeyCreateRequest,
    ApiKeyCreatedResponse,
    ApiKeyListItem,
    ApiKeyListResponse,
)
from app.services import api_key_service


router = APIRouter()


@router.get("", response_model=ApiKeyListResponse)
async def list_keys(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ApiKeyListResponse:
    keys = await api_key_service.list_for_user(db, current_user)
    return ApiKeyListResponse(
        keys=[
            ApiKeyListItem(
                id=k.id,
                name=k.name,
                key_prefix=k.key_prefix,
                scopes=list(k.scopes or []),
                last_used_at=k.last_used_at,
                revoked_at=k.revoked_at,
                created_at=k.created_at,
            )
            for k in keys
        ]
    )


@router.post("", response_model=ApiKeyCreatedResponse)
async def create_key(
    body: ApiKeyCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ApiKeyCreatedResponse:
    row, raw = await api_key_service.create_key(
        db, user=current_user, name=body.name, scopes=body.scopes
    )
    await db.commit()
    return ApiKeyCreatedResponse(
        id=row.id,
        name=row.name,
        raw_key=raw,
        key_prefix=row.key_prefix,
        scopes=list(row.scopes or []),
        created_at=row.created_at,
    )


@router.delete("/{key_id}")
async def revoke_key(
    key_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    ok = await api_key_service.revoke(db, current_user, key_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Key not found")
    await db.commit()
    return {"revoked": True}
