"""
Audit service — read-only access to the tenant's audit log.
"""
from __future__ import annotations

import csv
import io
import logging
from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.audit_log import AuditLog
from app.models.user import User


logger = logging.getLogger(__name__)


class AuditService:
    """List and export audit events for a tenant."""

    def __init__(self, tenant_id: str):
        self.tenant_id = tenant_id

    async def list_events(
        self,
        db: AsyncSession,
        *,
        page: int = 1,
        page_size: int = 50,
        action: Optional[str] = None,
        user_id: Optional[str] = None,
        resource_type: Optional[str] = None,
        from_ts: Optional[datetime] = None,
        to_ts: Optional[datetime] = None,
    ) -> Tuple[List[Dict[str, Any]], int]:
        """Return (events, total) for the tenant. Events are newest-first."""
        page = max(1, int(page))
        page_size = max(1, min(200, int(page_size)))

        conditions = [AuditLog.tenant_id == self.tenant_id]
        if action:
            conditions.append(AuditLog.action == action)
        if user_id:
            conditions.append(AuditLog.user_id == user_id)
        if resource_type:
            conditions.append(AuditLog.resource_type == resource_type)
        if from_ts is not None:
            conditions.append(AuditLog.created_at >= from_ts)
        if to_ts is not None:
            conditions.append(AuditLog.created_at <= to_ts)

        where = and_(*conditions)

        # Count
        total_stmt = select(func.count()).select_from(AuditLog).where(where)
        total = int((await db.execute(total_stmt)).scalar_one() or 0)

        # Page
        stmt = (
            select(AuditLog, User.email)
            .outerjoin(User, User.id == AuditLog.user_id)
            .where(where)
            .order_by(AuditLog.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        rows = (await db.execute(stmt)).all()

        events: List[Dict[str, Any]] = []
        for audit, email in rows:
            events.append({
                "id": audit.id,
                "created_at": audit.created_at,
                "user_id": audit.user_id,
                "user_email": email,
                "action": audit.action,
                "resource_type": audit.resource_type,
                "resource_id": audit.resource_id,
                "ip_address": audit.ip_address,
                "user_agent": audit.user_agent,
                "details": audit.details,
            })

        return events, total

    async def export_csv(
        self,
        db: AsyncSession,
        *,
        action: Optional[str] = None,
        user_id: Optional[str] = None,
        resource_type: Optional[str] = None,
        from_ts: Optional[datetime] = None,
        to_ts: Optional[datetime] = None,
        max_rows: int = 10_000,
    ) -> str:
        """Stream the filtered events as CSV (capped at max_rows)."""
        # Re-use list_events but with a large page_size; cap for safety
        events, _ = await self.list_events(
            db,
            page=1,
            page_size=max_rows,
            action=action,
            user_id=user_id,
            resource_type=resource_type,
            from_ts=from_ts,
            to_ts=to_ts,
        )

        buf = io.StringIO()
        writer = csv.writer(buf)
        writer.writerow([
            "id", "created_at", "user_id", "user_email", "action",
            "resource_type", "resource_id", "ip_address", "user_agent", "details",
        ])
        for ev in events:
            writer.writerow([
                ev["id"],
                ev["created_at"].isoformat() if ev["created_at"] else "",
                ev["user_id"] or "",
                ev["user_email"] or "",
                ev["action"],
                ev["resource_type"] or "",
                ev["resource_id"] or "",
                ev["ip_address"] or "",
                ev["user_agent"] or "",
                str(ev["details"]) if ev["details"] is not None else "",
            ])
        return buf.getvalue()
