"""
Audit log schemas.

Read-only responses for the audit log viewer.
"""
from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel


class AuditEventResponse(BaseModel):
    """One audit event."""
    id: str
    created_at: datetime
    user_id: Optional[str] = None
    user_email: Optional[str] = None     # joined from users
    action: str
    resource_type: Optional[str] = None
    resource_id: Optional[str] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    details: Optional[Dict[str, Any]] = None


class AuditListResponse(BaseModel):
    """Paginated audit event list."""
    events: List[AuditEventResponse]
    total: int
    page: int
    page_size: int
