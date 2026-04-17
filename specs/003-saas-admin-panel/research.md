# Phase 0 — Research & Decisions

**Feature**: SaaS Admin Panel
**Spec**: [spec.md](./spec.md)

Seven design questions resolved here.

---

## Decision 1 — Mailer library

**Decision**: `aiosmtplib`.

**Rationale**: Async-native (matches FastAPI's runtime), small pure-Python dep (no binaries), supports STARTTLS + implicit-SSL + plain, same SMTP_URL config pattern everyone knows. `fastapi-mail` adds Pydantic wrappers we don't need. `smtplib` in a thread works but adds sync/async boundary code.

**Alternatives considered**:
- `fastapi-mail`: heavier, opinionated template system we don't need.
- `sendgrid-python`: vendor lock-in, extra dep, requires account.
- `smtplib` in thread: works but clunky.

---

## Decision 2 — Invite token storage

**Decision**: Store SHA-256 hash of the token in the DB; return the raw token once in the response / email link; never log the raw token.

**Rationale**: Same pattern used for password reset tokens and (later) API keys. If the DB is leaked, tokens can't be replayed. Cost: we can't resend the same token — admin must revoke + create a new invite if the user loses the original email, which is actually the safer default.

---

## Decision 3 — Invite TTL

**Decision**: 7 days, with an admin-facing "Resend" button that creates a new token and deactivates the old one.

**Rationale**: Industry norm (GitHub, Slack, Linear all use 7 days). Long enough for inbox delays; short enough that dormant invites don't create long-lived attack windows.

---

## Decision 4 — Plan-limit enforcement location

**Decision**: FastAPI dependency on the guarded endpoints. Limits live in `backend/app/core/limits.py`:

```python
async def require_user_quota(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    tenant = await get_tenant(db, current_user.tenant_id)
    current_count = await count_tenant_users(db, tenant.id)
    if current_count >= tenant.limits.get("max_users", 10):
        raise HTTPException(
            status_code=402,
            detail=f"Plan limit reached: maximum {tenant.limits['max_users']} users.",
            headers={"X-Usage-Remaining": "0"},
        )
```

**Rationale**: Endpoint-scoped = easy to enable/disable per route; dependency = same pattern as `get_current_user`. Centralised rules in one module so a new limit type is one file to touch.

**Alternatives considered**:
- Middleware: too coarse; not every request is limit-checked.
- Service layer: harder to reason about, scatters limit checks across codebase.

---

## Decision 5 — TOTP library

**Decision**: `pyotp`.

**Rationale**: De-facto standard. Tiny (~200 lines), zero transitive deps, well-tested, actively maintained. Exposes `TOTP(secret).now()`, `TOTP(secret).verify(code, valid_window=1)`, `random_base32()` — nothing more needed.

**Alternatives**: `oathtool` (CLI, not a library), writing it from RFC 6238 (unnecessary).

---

## Decision 6 — API-key format

**Decision**: `lucent_<32 random base62 chars>`. Stored as SHA-256 of the raw value. Shown once on creation.

**Rationale**: Matches GitHub PAT pattern. The `lucent_` prefix makes accidental commits of keys greppable by security tooling. 32 base62 chars ≈ 190 bits of entropy, well above brute-force risk.

**Scope model**: two scopes for v1 — `read` (GET only) and `write` (GET + POST + PUT + DELETE). More granular scopes can be added without schema change (scopes is a JSON array).

---

## Decision 7 — Audit log retention

**Decision**: Default 365-day retention, controlled by `TENANT_AUDIT_RETENTION_DAYS` env var. Soft cleanup via a weekly cron (Celery beat) that deletes rows older than the threshold.

**Rationale**: Compliance rules (SOC 2, ISO 27001) typically require 1 year. Making it configurable lets paid tiers extend retention without schema changes.

**Alternative rejected**: indefinite retention would let the table grow unbounded on a shared Postgres instance; too risky for a SaaS.

---

## Testing Strategy

1. **Unit tests** (pytest):
   - `invite_service.create` produces unique hashes; expired tokens rejected.
   - `limit_enforcer.check_user_quota` returns False when over limit.
   - `mfa_service.verify` accepts valid TOTP, rejects wrong code, consumes backup code.
   - `api_key_service.authenticate` returns the user when hash matches, 401 otherwise.

2. **Integration tests** (pytest + httpx):
   - Invite flow end-to-end: POST /users/invite → accept-invite → new user logs in.
   - Plan limit enforcement: set max_users=2, create 3 users, confirm 402 on the 3rd.

3. **Manual walkthroughs** ([quickstart.md](./quickstart.md)): one per user story.
