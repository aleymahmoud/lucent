"""
Usage endpoint — tenant admin view of current usage vs plan limits.
"""
from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_tenant_admin, get_db
from app.models.user import User
from app.schemas.usage import UsageResponse
from app.services.usage_service import get_tenant_usage


router = APIRouter()


@router.get("/current/usage", response_model=UsageResponse)
async def read_current_usage(
    current_user: User = Depends(get_current_tenant_admin),
    db: AsyncSession = Depends(get_db),
) -> UsageResponse:
    return await get_tenant_usage(db, current_user.tenant_id)
