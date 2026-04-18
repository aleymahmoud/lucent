"""
Integration test fixtures.

Strategy: use FastAPI's TestClient with dependency overrides. No real DB
or Redis required — auth dependencies return a stub User; Redis calls
are stubbed via monkeypatching `get_redis`.

All integration tests are marked with `@pytest.mark.integration` so they
can be filtered out of the fast inner-loop.
"""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import Iterator

import pytest
from fastapi.testclient import TestClient

from app.core.deps import (
    get_current_platform_admin,
    get_current_tenant_admin,
    get_current_user,
    get_db,
)
from app.main import app
from app.models.user import User, UserRole


def _make_fake_user(role: UserRole = UserRole.ADMIN) -> User:
    """Instantiate a non-persisted User suitable for dependency stubs."""
    u = User()
    u.id = str(uuid.uuid4())
    u.tenant_id = str(uuid.uuid4())
    u.email = "test@example.com"
    u.full_name = "Test User"
    u.role = role
    u.is_active = True
    u.is_approved = True
    u.mfa_enabled = False
    u.mfa_secret = None
    u.mfa_backup_codes = None
    u.created_at = datetime.utcnow()
    u.updated_at = datetime.utcnow()
    u.last_login = None
    return u


class _FakeAdmin:
    """Stand-in for PlatformAdmin — only the attributes `get_current_platform_admin` touches."""
    def __init__(self):
        self.id = str(uuid.uuid4())
        self.email = "platform@example.com"
        self.is_active = True


@pytest.fixture
def tenant_admin_client() -> Iterator[TestClient]:
    """TestClient authenticated as a tenant admin via dependency overrides."""
    fake_user = _make_fake_user(UserRole.ADMIN)

    async def _fake_user_dep():
        return fake_user

    async def _fake_db_dep():
        # Yield None — most endpoints still work because we override the
        # service layer at a higher level. Tests that actually need DB
        # should skip themselves.
        yield None

    app.dependency_overrides[get_current_user] = _fake_user_dep
    app.dependency_overrides[get_current_tenant_admin] = _fake_user_dep
    app.dependency_overrides[get_db] = _fake_db_dep

    with TestClient(app) as client:
        yield client

    app.dependency_overrides.clear()


@pytest.fixture
def analyst_client() -> Iterator[TestClient]:
    """TestClient authenticated as a non-admin analyst."""
    fake_user = _make_fake_user(UserRole.ANALYST)

    async def _fake_user_dep():
        return fake_user

    async def _tenant_admin_forbidden():
        from fastapi import HTTPException, status
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Tenant admin access required")

    async def _fake_db_dep():
        yield None

    app.dependency_overrides[get_current_user] = _fake_user_dep
    app.dependency_overrides[get_current_tenant_admin] = _tenant_admin_forbidden
    app.dependency_overrides[get_db] = _fake_db_dep

    with TestClient(app) as client:
        yield client

    app.dependency_overrides.clear()


@pytest.fixture
def anonymous_client() -> Iterator[TestClient]:
    """TestClient with no auth overrides; 401/403 expected on protected routes."""
    with TestClient(app) as client:
        yield client


@pytest.fixture
def platform_admin_client() -> Iterator[TestClient]:
    """TestClient authenticated as a platform super-admin."""
    fake_admin = _FakeAdmin()

    async def _fake_admin_dep():
        return fake_admin

    async def _fake_db_dep():
        yield None

    app.dependency_overrides[get_current_platform_admin] = _fake_admin_dep
    app.dependency_overrides[get_db] = _fake_db_dep

    with TestClient(app) as client:
        yield client

    app.dependency_overrides.clear()
