"""
Admin Pydantic Schemas - Platform Admin operations
"""
from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime


# ============================================
# Tenant Schemas
# ============================================

class TenantCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    slug: str = Field(..., min_length=1, max_length=100, pattern=r'^[a-z0-9-]+$')
    settings: Optional[dict] = {}
    limits: Optional[dict] = None


class TenantUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    slug: Optional[str] = Field(None, min_length=1, max_length=100, pattern=r'^[a-z0-9-]+$')
    settings: Optional[dict] = None
    limits: Optional[dict] = None
    is_active: Optional[bool] = None


class TenantResponse(BaseModel):
    id: str
    name: str
    slug: str
    settings: dict
    limits: dict
    is_active: bool
    created_at: datetime
    updated_at: datetime
    user_count: Optional[int] = 0

    class Config:
        from_attributes = True


class TenantListResponse(BaseModel):
    tenants: List[TenantResponse]
    total: int


# ============================================
# User Schemas (Admin view)
# ============================================

class AdminUserCreate(BaseModel):
    """Create a tenant admin user"""
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=100)
    full_name: str = Field(..., min_length=1, max_length=255)
    role: str = Field(default="admin", pattern=r'^(admin|analyst|viewer)$')


class AdminUserResponse(BaseModel):
    id: str
    email: str
    full_name: Optional[str] = None
    role: str
    tenant_id: str
    tenant_name: Optional[str] = None
    is_active: bool
    is_approved: bool
    created_at: datetime
    last_login: Optional[datetime] = None

    class Config:
        from_attributes = True


class AdminUserListResponse(BaseModel):
    users: List[AdminUserResponse]
    total: int


# ============================================
# Stats Schemas
# ============================================

class PlatformStats(BaseModel):
    total_tenants: int
    active_tenants: int
    total_users: int
    active_users: int
    pending_approvals: int
