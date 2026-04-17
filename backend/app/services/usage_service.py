"""
Usage service — compute current usage vs tenant plan limits.

Reads from existing tables only:
  - users (active count)
  - forecast_history (count since the start of the current month)
"""
from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, Literal

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.forecast_history import ForecastHistory
from app.models.tenant import Tenant
from app.models.user import User
from app.schemas.usage import UsageMetric, UsageResponse


def _classify(current: int, limit: int) -> Literal["ok", "warn", "exceeded"]:
    if limit <= 0:
        return "ok"
    if current >= limit:
        return "exceeded"
    if current >= limit * 0.8:
        return "warn"
    return "ok"


def _pct(current: int, limit: int) -> float:
    if limit <= 0:
        return 0.0
    return round(current / limit * 100.0, 1)


async def _get_tenant_limits(db: AsyncSession, tenant_id: str) -> Dict[str, Any]:
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


async def get_tenant_usage(
    db: AsyncSession, tenant_id: str
) -> UsageResponse:
    """Compute usage metrics for the given tenant."""
    limits = await _get_tenant_limits(db, tenant_id)
    max_users = int(limits.get("max_users", 10))
    # There is no existing `max_forecasts_per_month` in the schema —
    # infer from hourly rate or default to 1000/month.
    max_forecasts_month = int(
        limits.get("max_forecasts_per_month")
        or limits.get("rate_limit_forecasts_per_hour", 20) * 24 * 30
    )

    # Active user count
    user_count = await db.scalar(
        select(func.count(User.id)).where(
            User.tenant_id == tenant_id,
            User.is_active == True,  # noqa: E712
        )
    ) or 0

    # Forecasts since start of current month
    now = datetime.utcnow()
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    forecast_month_count = await db.scalar(
        select(func.count(ForecastHistory.id)).where(
            ForecastHistory.tenant_id == tenant_id,
            ForecastHistory.created_at >= month_start,
        )
    ) or 0

    return UsageResponse(
        users=UsageMetric(
            current=int(user_count),
            limit=max_users,
            pct=_pct(int(user_count), max_users),
            status=_classify(int(user_count), max_users),
        ),
        forecasts_this_month=UsageMetric(
            current=int(forecast_month_count),
            limit=max_forecasts_month,
            pct=_pct(int(forecast_month_count), max_forecasts_month),
            status=_classify(int(forecast_month_count), max_forecasts_month),
        ),
    )


async def count_active_users(db: AsyncSession, tenant_id: str) -> int:
    return int(await db.scalar(
        select(func.count(User.id)).where(
            User.tenant_id == tenant_id,
            User.is_active == True,  # noqa: E712
        )
    ) or 0)


async def count_forecasts_this_month(db: AsyncSession, tenant_id: str) -> int:
    now = datetime.utcnow()
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    return int(await db.scalar(
        select(func.count(ForecastHistory.id)).where(
            ForecastHistory.tenant_id == tenant_id,
            ForecastHistory.created_at >= month_start,
        )
    ) or 0)
