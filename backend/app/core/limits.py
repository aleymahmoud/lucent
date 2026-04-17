"""
Central plan-limit enforcement.

FastAPI dependencies that raise HTTP 402 (Payment Required) when the
caller's tenant is at or above a plan limit. Used by mutation endpoints
that create a limited resource.
"""
from __future__ import annotations

import logging
from typing import Any, Dict

from fastapi import Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.tenant import Tenant
from app.models.user import User
from app.services.usage_service import (
    count_active_users,
    count_forecasts_this_month,
)


logger = logging.getLogger(__name__)


async def _get_limits(db: AsyncSession, tenant_id: str) -> Dict[str, Any]:
    t = await db.scalar(select(Tenant).where(Tenant.id == tenant_id))
    if t is None:
        return {}
    raw = t.limits or {}
    if isinstance(raw, str):
        import json
        try:
            raw = json.loads(raw)
        except Exception:
            raw = {}
    return raw if isinstance(raw, dict) else {}


async def require_user_quota(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    """Raise 402 if the tenant is at its max_users limit."""
    limits = await _get_limits(db, current_user.tenant_id)
    max_users = int(limits.get("max_users", 10))
    current = await count_active_users(db, current_user.tenant_id)
    if current >= max_users:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail=(
                f"Plan limit reached: maximum {max_users} users "
                f"(currently {current}). Upgrade your plan to add more."
            ),
            headers={"X-Usage-Remaining": "0"},
        )


async def require_forecast_quota(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    """Raise 402 if the tenant hits the monthly forecast cap."""
    limits = await _get_limits(db, current_user.tenant_id)
    max_month = int(
        limits.get("max_forecasts_per_month")
        or limits.get("rate_limit_forecasts_per_hour", 20) * 24 * 30
    )
    if max_month <= 0:
        return
    current = await count_forecasts_this_month(db, current_user.tenant_id)
    if current >= max_month:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail=(
                f"Plan limit reached: maximum {max_month} forecasts per month "
                f"(currently {current}). Upgrade or wait for next month."
            ),
            headers={"X-Usage-Remaining": "0"},
        )
