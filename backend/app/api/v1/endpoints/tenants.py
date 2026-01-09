"""
Public Tenant Endpoints - For validating tenant slugs
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel

from app.core.deps import get_db
from app.models.tenant import Tenant

router = APIRouter()


class TenantPublicResponse(BaseModel):
    """Public tenant info (minimal data for URL validation)"""
    id: str
    slug: str
    name: str
    is_active: bool

    class Config:
        from_attributes = True


@router.get("/{slug}", response_model=TenantPublicResponse)
async def get_tenant_by_slug(
    slug: str,
    db: AsyncSession = Depends(get_db)
):
    """
    Get tenant by slug (public endpoint for URL validation)

    Used by frontend to validate tenant slugs in URLs.
    Only returns minimal public information.
    """
    result = await db.execute(
        select(Tenant).where(Tenant.slug == slug)
    )
    tenant = result.scalar_one_or_none()

    if not tenant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tenant not found"
        )

    if not tenant.is_active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tenant not found"
        )

    return TenantPublicResponse(
        id=tenant.id,
        slug=tenant.slug,
        name=tenant.name,
        is_active=tenant.is_active
    )
