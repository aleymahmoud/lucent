"""
Auth-guard integration tests.

Confirm that tenant-admin-scoped routes 403 non-admins and 401 the
anonymous client. Doesn't exercise DB logic — just routing + dependency
enforcement.
"""
from __future__ import annotations

import pytest


pytestmark = pytest.mark.integration


# ------------------------------------------------------------------
# Audit — tenant admin only
# ------------------------------------------------------------------

def test_audit_list_requires_auth(anonymous_client):
    res = anonymous_client.get("/api/v1/audit")
    assert res.status_code in (401, 403)


def test_audit_list_forbids_analyst(analyst_client):
    res = analyst_client.get("/api/v1/audit")
    assert res.status_code == 403


# ------------------------------------------------------------------
# Usage — tenant admin only
# ------------------------------------------------------------------

def test_usage_requires_auth(anonymous_client):
    res = anonymous_client.get("/api/v1/tenants/current/usage")
    assert res.status_code in (401, 403)


def test_usage_forbids_analyst(analyst_client):
    res = analyst_client.get("/api/v1/tenants/current/usage")
    assert res.status_code == 403


# ------------------------------------------------------------------
# Invites — tenant admin only
# ------------------------------------------------------------------

def test_invite_requires_auth(anonymous_client):
    res = anonymous_client.post("/api/v1/users/invite", json={
        "email": "a@b.com", "role": "analyst"
    })
    assert res.status_code in (401, 403)


def test_invite_forbids_analyst(analyst_client):
    res = analyst_client.post("/api/v1/users/invite", json={
        "email": "a@b.com", "role": "analyst"
    })
    assert res.status_code == 403


# ------------------------------------------------------------------
# Platform admin routes — super admin only
# ------------------------------------------------------------------

def test_admin_stats_requires_auth(anonymous_client):
    res = anonymous_client.get("/api/v1/admin/stats")
    assert res.status_code in (401, 403)


def test_admin_stats_forbids_tenant_admin(tenant_admin_client):
    """A tenant admin is not a platform admin."""
    res = tenant_admin_client.get("/api/v1/admin/stats")
    assert res.status_code in (401, 403)


# ------------------------------------------------------------------
# Public route — accept-invite should not require auth
# ------------------------------------------------------------------

def test_accept_invite_is_public(anonymous_client):
    """Accept endpoint returns 400/410 for bad token, not 401."""
    res = anonymous_client.post("/api/v1/accept-invite", json={
        "token": "definitely-not-a-real-token",
        "full_name": "X",
        "password": "pw123456",
    })
    assert res.status_code in (400, 410, 422)  # reject payload, not auth
