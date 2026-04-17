"""
Invite schemas — create invite, accept invite, list invites.
"""
from __future__ import annotations

from datetime import datetime
from typing import List, Literal, Optional

from pydantic import BaseModel, EmailStr, Field


class InviteCreateRequest(BaseModel):
    email: EmailStr
    role: Literal["admin", "analyst", "viewer"]
    group_id: Optional[str] = None


class InviteCreatedResponse(BaseModel):
    id: str
    email: str
    role: str
    expires_at: datetime
    invite_link: Optional[str] = None     # populated when SMTP is not configured


class InviteListItem(BaseModel):
    id: str
    email: str
    role: str
    expires_at: datetime
    used_at: Optional[datetime] = None
    created_at: datetime
    created_by_email: Optional[str] = None


class InviteListResponse(BaseModel):
    invites: List[InviteListItem]


class AcceptInviteRequest(BaseModel):
    token: str
    full_name: str = Field(..., min_length=1, max_length=255)
    password: str = Field(..., min_length=6, max_length=128)
