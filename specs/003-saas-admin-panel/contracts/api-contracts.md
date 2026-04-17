# Phase 1 — API Contracts

**Feature**: SaaS Admin Panel
**Plan**: [../plan.md](../plan.md)

## Endpoint Summary

Endpoints grouped by priority / user story.

### P1 — Platform admin UIs + Audit log

| Method | Path | Auth | Status | Purpose |
|--------|------|------|--------|---------|
| GET | `/admin/tenants` | super-admin | EXISTS | List all tenants |
| POST | `/admin/tenants` | super-admin | EXISTS | Create a tenant |
| GET | `/admin/tenants/{id}` | super-admin | EXISTS | Get tenant detail |
| PATCH | `/admin/tenants/{id}` | super-admin | EXISTS | Update tenant |
| DELETE | `/admin/tenants/{id}` | super-admin | EXISTS | Deactivate tenant |
| GET | `/admin/users` | super-admin | EXISTS | Cross-tenant user list |
| POST | `/admin/users/{id}/approve` | super-admin | EXISTS | Approve pending user |
| POST | `/admin/users/{id}/deactivate` | super-admin | EXISTS | Deactivate user |
| GET | `/admin/stats` | super-admin | EXISTS | Platform-wide stats |
| GET | `/audit` | tenant-admin | **NEW** | List audit events for caller's tenant |
| GET | `/audit/export` | tenant-admin | **NEW** | CSV export of filtered events |

### P2 — Invites + Usage + Limit enforcement

| Method | Path | Auth | Status | Purpose |
|--------|------|------|--------|---------|
| POST | `/users/invite` | tenant-admin | NEW | Create invite token, send email |
| GET | `/users/invites` | tenant-admin | NEW | List pending invites |
| DELETE | `/users/invites/{id}` | tenant-admin | NEW | Revoke an invite |
| POST | `/users/invites/{id}/resend` | tenant-admin | NEW | New token, invalidate old |
| POST | `/accept-invite` | public | NEW | Exchange token for user |
| GET | `/tenants/current/usage` | tenant-admin | NEW | Current usage vs limits |
| (limit enforcement) | various | — | NEW | 402 responses on `POST /users`, `POST /users/invite`, `POST /forecast/run`, `POST /forecast/batch` when over limit |

### P3 — MFA + API Keys

| Method | Path | Auth | Status | Purpose |
|--------|------|------|--------|---------|
| POST | `/mfa/enroll` | user | NEW | Start enrollment; returns secret + QR + backup codes |
| POST | `/mfa/verify` | user | NEW | Confirm enrollment with a valid TOTP |
| POST | `/mfa/disable` | user | NEW | Disable 2FA (requires current password) |
| POST | `/auth/login` | public | MODIFY | If `mfa_enabled`, response is 202 with `require_mfa=true`; client calls `/auth/mfa/challenge` |
| POST | `/auth/mfa/challenge` | user (session bound) | NEW | Submit TOTP code to complete login |
| GET | `/api-keys` | user | NEW | List caller's own keys |
| POST | `/api-keys` | user | NEW | Create new key, return raw key once |
| DELETE | `/api-keys/{id}` | user | NEW | Revoke a key |

---

## P1 Contract Details

### `GET /audit`

Query parameters:
- `page`: int = 1
- `page_size`: int = 50 (max 200)
- `action`: str (optional, exact match)
- `user_id`: str (optional)
- `resource_type`: str (optional)
- `from`: ISO datetime (optional)
- `to`: ISO datetime (optional)

Response:
```jsonc
{
  "events": [
    {
      "id": "uuid",
      "created_at": "2026-04-17T12:34:56Z",
      "user_id": "uuid",
      "user_email": "alice@example.com",
      "action": "login",
      "resource_type": "auth",
      "resource_id": null,
      "ip_address": "10.0.0.1",
      "user_agent": "Mozilla/5.0 ...",
      "details": { "tenant_slug": "acme" }
    }
  ],
  "total": 1234,
  "page": 1,
  "page_size": 50
}
```

Errors: 403 when caller is not a tenant admin.

### `GET /audit/export`

Same query parameters as `/audit`; streams CSV.

---

## P2 Contract Details (abbreviated)

### `POST /users/invite`

Request: `{ "email": "...", "role": "analyst", "group_id": null }`

Response: `{ "id": "...", "email": "...", "expires_at": "...", "invite_link": null }`

- `invite_link` is populated ONLY when SMTP is not configured (admin must share manually).
- Returns 402 when tenant is at `max_users`.

### `POST /accept-invite`

Request: `{ "token": "...", "full_name": "...", "password": "..." }`

Response: standard session tokens (same shape as login response). The user is created and immediately authenticated.

Errors: 410 when token expired or already used; 400 when password doesn't meet complexity rules.

### `GET /tenants/current/usage`

Response:
```jsonc
{
  "users": { "current": 7, "limit": 10, "pct": 70.0, "status": "ok" },
  "forecasts_this_month": { "current": 84, "limit": 100, "pct": 84.0, "status": "warn" },
  "storage_mb": { "current": 450, "limit": 2000, "pct": 22.5, "status": "ok" }
}
```

`status` ranges: `"ok"` (<60%), `"warn"` (60–90%), `"exceeded"` (≥100%). "exceeded" does not necessarily mean the action is blocked — that depends on whether the endpoint enforces the limit.

---

## P3 Contract Details (abbreviated)

### `POST /mfa/enroll`

Response:
```jsonc
{
  "secret": "JBSWY3DPEHPK3PXP",
  "qr_uri": "otpauth://totp/LUCENT:alice@example.com?secret=...&issuer=LUCENT",
  "backup_codes": ["1a2b-3c4d", "..."]
}
```

Backup codes returned plaintext ONLY here; stored hashed.

### `POST /api-keys`

Request: `{ "name": "Prod deploy bot", "scopes": ["read", "write"] }`

Response:
```jsonc
{
  "id": "uuid",
  "name": "Prod deploy bot",
  "raw_key": "lucent_abc123...",   // shown once
  "key_prefix": "lucent_a",
  "scopes": ["read", "write"],
  "created_at": "..."
}
```

`raw_key` is never returned again. Subsequent GET only shows `key_prefix`.

---

## Backward Compatibility

All new endpoints are additive. Existing clients unaffected. Role checks at the handler layer preserve current tenant isolation. The user/tenant schemas get new optional columns (P3); the API response shapes don't change for non-admin / non-MFA users.
