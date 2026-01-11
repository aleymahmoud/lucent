"""
Tenant Branding Schemas
"""
from pydantic import BaseModel, Field, HttpUrl
from typing import Optional


class BrandingColors(BaseModel):
    """Color scheme for tenant branding"""
    primary: str = Field(default="#2563eb", description="Primary brand color (hex)")
    secondary: str = Field(default="#1e40af", description="Secondary brand color (hex)")
    accent: str = Field(default="#3b82f6", description="Accent color (hex)")


class BrandingSettings(BaseModel):
    """Complete branding settings for a tenant"""
    logo_url: Optional[str] = Field(default=None, description="URL to tenant logo")
    favicon_url: Optional[str] = Field(default=None, description="URL to favicon")
    login_bg_url: Optional[str] = Field(default=None, description="URL to login page background image")
    login_message: Optional[str] = Field(default=None, max_length=500, description="Custom welcome message on login page")
    colors: BrandingColors = Field(default_factory=BrandingColors)

    class Config:
        from_attributes = True


class BrandingUpdate(BaseModel):
    """Update branding settings - all fields optional"""
    logo_url: Optional[str] = None
    favicon_url: Optional[str] = None
    login_bg_url: Optional[str] = None
    login_message: Optional[str] = Field(default=None, max_length=500)
    colors: Optional[BrandingColors] = None


class BrandingResponse(BaseModel):
    """Response with branding settings and tenant info"""
    tenant_id: str
    tenant_name: str
    tenant_slug: str
    branding: BrandingSettings

    class Config:
        from_attributes = True
