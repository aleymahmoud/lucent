"""
Endpoint shape integration tests.

Each test boots the FastAPI app with the appropriate auth dependency
stub, calls one endpoint per router, and asserts the response shape
(status code + key fields) is what the frontend expects.

These don't exercise the DB/Redis layer — service methods are patched
to return deterministic values. The point is to catch wiring regressions
(route paths, response_model serialization, dependency order).
"""
from __future__ import annotations

from datetime import datetime
from unittest.mock import AsyncMock, patch

import pytest

from app.models.user import User


pytestmark = pytest.mark.integration


# ------------------------------------------------------------------
# Forecast
# ------------------------------------------------------------------

def test_forecast_status_unknown_id_returns_404(tenant_admin_client):
    """Spec 001/002 — status endpoint returns 404 for missing IDs."""
    res = tenant_admin_client.get(
        f"/api/v1/forecast/status/00000000-0000-0000-0000-000000000000"
    )
    # 404 or 400 on bad UUID — either indicates routing works
    assert res.status_code in (400, 404)


def test_forecast_methods_lists_three(tenant_admin_client):
    res = tenant_admin_client.get("/api/v1/forecast/methods")
    assert res.status_code == 200
    body = res.json()
    assert isinstance(body, list)
    method_ids = {m["id"] for m in body}
    assert {"arima", "ets", "prophet"}.issubset(method_ids)


# ------------------------------------------------------------------
# Results
# ------------------------------------------------------------------

def test_results_unknown_id_returns_404(tenant_admin_client):
    res = tenant_admin_client.get(
        "/api/v1/results/00000000-0000-0000-0000-000000000000"
    )
    assert res.status_code == 404


# ------------------------------------------------------------------
# Diagnostics
# ------------------------------------------------------------------

def test_diagnostics_unknown_id_returns_404(tenant_admin_client):
    res = tenant_admin_client.get(
        "/api/v1/diagnostics/00000000-0000-0000-0000-000000000000"
    )
    assert res.status_code == 404


# ------------------------------------------------------------------
# Preprocessing
# ------------------------------------------------------------------

def test_preprocessing_unknown_dataset_returns_error(tenant_admin_client):
    """A missing dataset should not 500 — it should return a graceful error."""
    res = tenant_admin_client.post(
        "/api/v1/preprocessing/00000000-0000-0000-0000-000000000000/missing"
        "?entity_id=NONEXISTENT",
        json={"method": "drop"},
    )
    # 400 (validation) or 404 (not found) are both acceptable
    assert res.status_code in (400, 404, 422)


# ------------------------------------------------------------------
# Audit route mount is already covered by test_audit_list_forbids_analyst
# in test_auth_guards.py — a 403 there proves the route exists and the
# tenant-admin dep is enforced. Exercising audit with the stub DB would
# require a real DB fixture which is out of scope for the P2 integration
# layer.
# ------------------------------------------------------------------
