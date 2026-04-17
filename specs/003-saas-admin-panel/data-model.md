# Phase 1 — Data Model

**Feature**: SaaS Admin Panel
**Plan**: [plan.md](./plan.md)

## Schema Changes (grouped by phase)

### P1 (no schema changes)

The P1 tier (admin UIs + audit log) uses only existing tables (`tenants`, `users`, `forecast_history`, `audit_logs`). No migrations.

---

### P2 — Invite flow + usage quotas

#### New table: `invites`

```sql
CREATE TABLE invites (
    id              UUID PRIMARY KEY,
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    email           VARCHAR(255) NOT NULL,
    role            VARCHAR(32) NOT NULL,             -- matches users.role
    token_hash      VARCHAR(64) NOT NULL UNIQUE,      -- SHA-256 hex
    expires_at      TIMESTAMP WITH TIME ZONE NOT NULL,
    used_at         TIMESTAMP WITH TIME ZONE NULL,    -- null until acceptance
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    group_id        UUID NULL REFERENCES groups(id)   -- optional default group
);

CREATE INDEX idx_invites_tenant ON invites(tenant_id);
CREATE INDEX idx_invites_email ON invites(email);
CREATE INDEX idx_invites_expires ON invites(expires_at) WHERE used_at IS NULL;
```

#### Modified: `users.status` enum

Add `pending_invite` value to the existing status enum. Existing values (`active`, `pending_approval`, `inactive`) unchanged.

#### No table change for usage

Usage is computed on demand from existing tables:
- users: `SELECT COUNT(*) FROM users WHERE tenant_id = $1 AND status = 'active'`
- forecasts this month: `SELECT COUNT(*) FROM forecast_history WHERE tenant_id = $1 AND created_at > date_trunc('month', now())`
- storage: sum of dataset sizes (already tracked)

---

### P3 — MFA + API keys

#### Modified: `users` table

```sql
ALTER TABLE users
  ADD COLUMN mfa_secret           VARCHAR(64) NULL,    -- encrypted base32 TOTP secret
  ADD COLUMN mfa_enabled          BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN mfa_backup_codes     JSONB NULL;          -- list of SHA-256 hex strings
```

#### New table: `api_keys`

```sql
CREATE TABLE api_keys (
    id              UUID PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name            VARCHAR(128) NOT NULL,
    key_hash        VARCHAR(64) NOT NULL UNIQUE,       -- SHA-256 hex of raw key
    key_prefix      VARCHAR(16) NOT NULL,              -- first 8 chars for display
    scopes          JSONB NOT NULL DEFAULT '[]',       -- e.g. ["read"] or ["read","write"]
    last_used_at    TIMESTAMP WITH TIME ZONE NULL,
    revoked_at      TIMESTAMP WITH TIME ZONE NULL,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_api_keys_user ON api_keys(user_id);
CREATE INDEX idx_api_keys_tenant ON api_keys(tenant_id) WHERE revoked_at IS NULL;
```

---

## New Pydantic schemas

### P1: `app/schemas/audit.py`

```python
class AuditEventResponse(BaseModel):
    id: str
    created_at: datetime
    user_id: Optional[str]
    user_email: Optional[str]   # joined from users
    action: str
    resource_type: Optional[str]
    resource_id: Optional[str]
    ip_address: Optional[str]
    user_agent: Optional[str]
    details: Optional[Dict[str, Any]]

class AuditListResponse(BaseModel):
    events: List[AuditEventResponse]
    total: int
    page: int
    page_size: int
```

### P2: `app/schemas/invite.py`, `app/schemas/usage.py`

```python
class InviteCreateRequest(BaseModel):
    email: EmailStr
    role: Literal["admin", "analyst", "viewer"]
    group_id: Optional[str] = None

class InviteCreatedResponse(BaseModel):
    id: str
    email: str
    expires_at: datetime
    invite_link: Optional[str] = None  # populated only when SMTP is not configured

class AcceptInviteRequest(BaseModel):
    token: str
    full_name: str
    password: str

class UsageResponse(BaseModel):
    users:      UsageMetric  # {current, limit, pct, status: "ok"|"warn"|"exceeded"}
    forecasts_this_month: UsageMetric
    storage_mb: UsageMetric
```

### P3: `app/schemas/mfa.py`, `app/schemas/api_key.py`

```python
class MfaEnrollResponse(BaseModel):
    secret: str         # base32
    qr_uri: str         # otpauth:// URI for QR code
    backup_codes: List[str]  # shown once

class MfaVerifyRequest(BaseModel):
    code: str

class ApiKeyCreateRequest(BaseModel):
    name: str
    scopes: List[Literal["read", "write"]]

class ApiKeyCreatedResponse(BaseModel):
    id: str
    name: str
    raw_key: str        # shown once
    key_prefix: str
    scopes: List[str]
    created_at: datetime

class ApiKeyListItem(BaseModel):
    id: str
    name: str
    key_prefix: str
    scopes: List[str]
    last_used_at: Optional[datetime]
    revoked_at: Optional[datetime]
    created_at: datetime
```

---

## Frontend Types

Add to `frontend/src/types/index.ts`:

```typescript
export interface AuditEvent { ... }    // P1
export interface Invite { ... }        // P2
export interface UsageMetric { ... }   // P2
export interface MfaEnroll { ... }     // P3
export interface ApiKey { ... }        // P3
```

---

## Role Check Additions

`backend/app/core/deps.py` gains:

```python
async def require_super_admin(
    current_user: User = Depends(get_current_user),
) -> User:
    if not current_user.is_platform_admin:
        raise HTTPException(403, "Platform admin required")
    return current_user

async def require_tenant_admin(
    current_user: User = Depends(get_current_user),
) -> User:
    if current_user.role != "admin":
        raise HTTPException(403, "Tenant admin required")
    return current_user
```

Both deps protect every endpoint added by this spec.
