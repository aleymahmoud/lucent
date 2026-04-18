"""API key schemas."""
from __future__ import annotations

from datetime import datetime
from typing import List, Literal, Optional

from pydantic import BaseModel, Field


class ApiKeyCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=128)
    scopes: List[Literal["read", "write"]] = ["read"]


class ApiKeyCreatedResponse(BaseModel):
    id: str
    name: str
    raw_key: str         # shown once
    key_prefix: str
    scopes: List[str]
    created_at: datetime


class ApiKeyListItem(BaseModel):
    id: str
    name: str
    key_prefix: str
    scopes: List[str]
    last_used_at: Optional[datetime] = None
    revoked_at: Optional[datetime] = None
    created_at: datetime


class ApiKeyListResponse(BaseModel):
    keys: List[ApiKeyListItem]
