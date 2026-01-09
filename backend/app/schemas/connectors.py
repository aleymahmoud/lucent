"""
Connector RLS Schemas - For managing Row-Level Security on connectors
"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


# ============================================
# RLS Config Schemas
# ============================================

class ConnectorRLSCreate(BaseModel):
    """Create RLS config for a connector"""
    rls_column: str = Field(..., min_length=1, max_length=255)
    is_enabled: bool = True


class ConnectorRLSUpdate(BaseModel):
    """Update RLS config for a connector"""
    rls_column: Optional[str] = Field(None, min_length=1, max_length=255)
    is_enabled: Optional[bool] = None


class ConnectorRLSResponse(BaseModel):
    """RLS config response"""
    id: str
    connector_id: str
    rls_column: str
    is_enabled: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ============================================
# Connector Schemas (Basic - for RLS endpoints)
# ============================================

class ConnectorBasicResponse(BaseModel):
    """Basic connector info"""
    id: str
    name: str
    type: str
    is_active: bool
    created_at: datetime
    rls_config: Optional[ConnectorRLSResponse] = None

    class Config:
        from_attributes = True


class ConnectorListResponse(BaseModel):
    """Paginated connector list"""
    connectors: List[ConnectorBasicResponse]
    total: int


class ConnectorColumnsResponse(BaseModel):
    """Response for connector columns"""
    columns: List[str]
