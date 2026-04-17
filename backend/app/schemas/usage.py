"""Usage / plan limit schemas."""
from __future__ import annotations

from typing import Literal

from pydantic import BaseModel


class UsageMetric(BaseModel):
    current: int
    limit: int
    pct: float   # 0..100+
    status: Literal["ok", "warn", "exceeded"]


class UsageResponse(BaseModel):
    users: UsageMetric
    forecasts_this_month: UsageMetric
    # Storage omitted in P2 MVP — dataset size tracking isn't uniform.
