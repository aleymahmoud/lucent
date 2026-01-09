"""
User Group Schemas - For managing user groups and RLS values
"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


# ============================================
# Group CRUD Schemas
# ============================================

class GroupCreate(BaseModel):
    """Create a user group"""
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = Field(None, max_length=1000)
    rls_values: List[str] = Field(default=[])


class GroupUpdate(BaseModel):
    """Update a user group"""
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = Field(None, max_length=1000)
    rls_values: Optional[List[str]] = None
    is_active: Optional[bool] = None


class GroupMemberInfo(BaseModel):
    """Brief user info for group member"""
    id: str
    email: str
    full_name: Optional[str] = None
    role: str

    class Config:
        from_attributes = True


class GroupResponse(BaseModel):
    """Group response"""
    id: str
    name: str
    description: Optional[str] = None
    rls_values: List[str] = []
    is_active: bool
    created_at: datetime
    updated_at: datetime
    member_count: int = 0

    class Config:
        from_attributes = True


class GroupDetailResponse(BaseModel):
    """Group response with member list"""
    id: str
    name: str
    description: Optional[str] = None
    rls_values: List[str] = []
    is_active: bool
    created_at: datetime
    updated_at: datetime
    members: List[GroupMemberInfo] = []

    class Config:
        from_attributes = True


class GroupListResponse(BaseModel):
    """Paginated group list response"""
    groups: List[GroupResponse]
    total: int


# ============================================
# Group Membership Schemas
# ============================================

class AddGroupMember(BaseModel):
    """Add a member to a group"""
    user_id: str


class AddGroupMembers(BaseModel):
    """Add multiple members to a group"""
    user_ids: List[str]


class RemoveGroupMember(BaseModel):
    """Remove a member from a group"""
    user_id: str


class GroupMembershipResponse(BaseModel):
    """Membership operation response"""
    message: str
    group_id: str
    added_count: Optional[int] = None
    removed_count: Optional[int] = None
