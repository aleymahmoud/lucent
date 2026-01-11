"""
Public Tenant Endpoints - For validating tenant slugs and branding
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel

from app.core.deps import get_db, get_current_tenant_admin
from app.models.tenant import Tenant
from app.models.user import User
from app.schemas.branding import BrandingSettings, BrandingUpdate, BrandingResponse

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


def get_branding_from_settings(settings: dict) -> BrandingSettings:
    """Extract branding settings from tenant settings JSONB"""
    branding_data = settings.get("branding", {}) if settings else {}
    return BrandingSettings(**branding_data)


@router.get("/{slug}/branding", response_model=BrandingResponse)
async def get_tenant_branding(
    slug: str,
    db: AsyncSession = Depends(get_db)
):
    """
    Get tenant branding settings (public endpoint)

    Used by frontend to apply tenant-specific branding.
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

    branding = get_branding_from_settings(tenant.settings)

    return BrandingResponse(
        tenant_id=tenant.id,
        tenant_name=tenant.name,
        tenant_slug=tenant.slug,
        branding=branding
    )


@router.put("/{slug}/branding", response_model=BrandingResponse)
async def update_tenant_branding(
    slug: str,
    branding_update: BrandingUpdate,
    current_user: User = Depends(get_current_tenant_admin),
    db: AsyncSession = Depends(get_db)
):
    """
    Update tenant branding settings (tenant admin only)

    Only tenant admins can update their own tenant's branding.
    """
    # Get tenant
    result = await db.execute(
        select(Tenant).where(Tenant.slug == slug)
    )
    tenant = result.scalar_one_or_none()

    if not tenant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tenant not found"
        )

    # Verify user belongs to this tenant
    if current_user.tenant_id != tenant.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only update branding for your own tenant"
        )

    # Get current settings or initialize
    current_settings = tenant.settings or {}
    current_branding = current_settings.get("branding", {})

    # Update branding with provided values
    update_data = branding_update.model_dump(exclude_unset=True)

    # Handle nested colors update
    if "colors" in update_data and update_data["colors"]:
        current_colors = current_branding.get("colors", {})
        current_colors.update(update_data["colors"])
        update_data["colors"] = current_colors

    current_branding.update(update_data)
    current_settings["branding"] = current_branding

    # Save to database
    tenant.settings = current_settings
    await db.commit()
    await db.refresh(tenant)

    branding = get_branding_from_settings(tenant.settings)

    return BrandingResponse(
        tenant_id=tenant.id,
        tenant_name=tenant.name,
        tenant_slug=tenant.slug,
        branding=branding
    )
