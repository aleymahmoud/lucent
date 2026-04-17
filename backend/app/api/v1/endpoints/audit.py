"""
Audit log endpoints — tenant-scoped read + CSV export.
"""
from __future__ import annotations

from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_tenant_admin, get_db
from app.models.user import User
from app.schemas.audit import AuditEventResponse, AuditListResponse
from app.services.audit_service import AuditService


router = APIRouter()


@router.get("", response_model=AuditListResponse, summary="List audit events")
async def list_audit_events(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    action: Optional[str] = Query(None),
    user_id: Optional[str] = Query(None),
    resource_type: Optional[str] = Query(None),
    from_ts: Optional[datetime] = Query(None, alias="from"),
    to_ts: Optional[datetime] = Query(None, alias="to"),
    current_user: User = Depends(get_current_tenant_admin),
    db: AsyncSession = Depends(get_db),
) -> AuditListResponse:
    """
    List audit events for the caller's tenant.

    Requires tenant admin role. Filters are AND-combined.
    """
    service = AuditService(current_user.tenant_id)
    events, total = await service.list_events(
        db,
        page=page,
        page_size=page_size,
        action=action,
        user_id=user_id,
        resource_type=resource_type,
        from_ts=from_ts,
        to_ts=to_ts,
    )
    return AuditListResponse(
        events=[AuditEventResponse(**e) for e in events],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/export", summary="Export audit events as CSV", response_class=StreamingResponse)
async def export_audit_events(
    action: Optional[str] = Query(None),
    user_id: Optional[str] = Query(None),
    resource_type: Optional[str] = Query(None),
    from_ts: Optional[datetime] = Query(None, alias="from"),
    to_ts: Optional[datetime] = Query(None, alias="to"),
    current_user: User = Depends(get_current_tenant_admin),
    db: AsyncSession = Depends(get_db),
):
    """Stream the filtered events as CSV (capped at 10 000 rows)."""
    service = AuditService(current_user.tenant_id)
    csv_content = await service.export_csv(
        db,
        action=action,
        user_id=user_id,
        resource_type=resource_type,
        from_ts=from_ts,
        to_ts=to_ts,
    )
    filename = f"audit_log_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.csv"
    return StreamingResponse(
        iter([csv_content]),
        media_type="text/csv",
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
            "Content-Type": "text/csv; charset=utf-8",
        },
    )
