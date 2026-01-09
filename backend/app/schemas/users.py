"""
Tenant Admin User Schemas - For tenant admins to manage users within their tenant
"""
from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime


# ============================================
# User CRUD Schemas
# ============================================

class TenantUserCreate(BaseModel):
    """Create a user within the tenant"""
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=100)
    full_name: str = Field(..., min_length=1, max_length=255)
    role: str = Field(default="analyst", pattern=r'^(admin|analyst|viewer)$')


class TenantUserUpdate(BaseModel):
    """Update a user within the tenant"""
    full_name: Optional[str] = Field(None, min_length=1, max_length=255)
    role: Optional[str] = Field(None, pattern=r'^(admin|analyst|viewer)$')
    is_active: Optional[bool] = None
    is_approved: Optional[bool] = None


class GroupMembershipInfo(BaseModel):
    """Brief group info for user response"""
    id: str
    name: str

    class Config:
        from_attributes = True


class TenantUserResponse(BaseModel):
    """User response for tenant admin view"""
    id: str
    email: str
    full_name: Optional[str] = None
    role: str
    is_active: bool
    is_approved: bool
    created_at: datetime
    last_login: Optional[datetime] = None
    groups: List[GroupMembershipInfo] = []

    class Config:
        from_attributes = True


class TenantUserListResponse(BaseModel):
    """Paginated user list response"""
    users: List[TenantUserResponse]
    total: int


# ============================================
# Tenant Stats Schemas
# ============================================

class TenantStats(BaseModel):
    """Statistics for the tenant"""
    total_users: int
    active_users: int
    pending_approvals: int
    total_groups: int
    total_connectors: int
