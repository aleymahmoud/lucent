# Implementation Plan: SaaS Admin Panel

**Branch**: `003-saas-admin-panel` | **Date**: 2026-04-17 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-saas-admin-panel/spec.md`

## Summary

Complete the SaaS admin surface by (1) building UIs for the stubbed platform admin endpoints (`/admin/tenants`, `/admin/users`, `/admin/stats`), (2) adding a tenant-scoped audit log viewer reading from the existing `audit_logs` table, (3) introducing a user-invite flow with email delivery, (4) adding usage-vs-limit visibility and server-side enforcement, and (5) adding MFA and personal API keys for security hardening. Priorities staged so the P1 tier (admin UIs + audit log) ships first and the rest layers incrementally.

## Technical Context

**Language/Version**: Python 3.11 (backend), TypeScript 5 / Next.js 16 (frontend)
**Primary Dependencies**: FastAPI, SQLAlchemy 2.0, Pydantic v2, Alembic. New: `python-jose` (already installed for JWT), `pyotp` for TOTP, `aiosmtplib` or `fastapi-mail` for email, `secrets` stdlib for invite/API key tokens. Frontend adds no new deps.
**Storage**: Upstash Redis (invite token cache, optional) + Neon PostgreSQL (new `invites` + `api_keys` tables; `audit_logs` already exists)
**Testing**: pytest for backend services (invite lifecycle, limit enforcement, TOTP verification); manual walkthrough per `quickstart.md`.
**Target Platform**: Same as prior specs — Windows Server 2022 local PM2, production via Docker/Coolify.
**Project Type**: Web app monorepo.
**Performance Goals**: Admin pages render in < 1s for up to 1000 tenants / 10 000 users. Audit log query < 500ms for a 30-day window. Invite email send < 30s end-to-end.
**Constraints**: All new endpoints must enforce role at handler level; no new top-level Python deps for MVP (P1). SMTP config is optional — missing SMTP must not break any flow. New tables must be Alembic migrations, not manual SQL.
**Scale/Scope**: ~6 new frontend pages, ~8 new backend endpoints, 2 new DB tables, 2 new service modules. ~1500 lines of new code across both halves, majority frontend.

## Constitution Check

No `.specify/memory/constitution.md` authored. Implicit gates: CLAUDE.md file-ownership rules and the Discovery Before Creation protocol.

- **Discovery Before Creation**: New shared utilities (mailer, invite_service, api_key_service) must be registered in `docs/shared-registry.md`.
- **Database changes via Alembic only**: P2 migrations (`invites` table, `user.status` extension) go through `alembic revision --autogenerate`. P3 migrations (`api_keys`, `user.mfa_*`) same.
- **Role enforcement at handler layer**: every admin endpoint added in this spec must check `current_user.is_platform_admin` or `current_user.is_tenant_admin` before executing.

**Gate status**: PASS.

## Project Structure

### Documentation

```text
specs/003-saas-admin-panel/
├── plan.md              # This file
├── spec.md              # 10 user stories, 14 FRs, 7 success criteria
├── research.md          # Phase 0 — mailer lib, TOTP lib, API-key hashing, invite TTL
├── data-model.md        # Schema diffs: Invite, ApiKey, User.status extension, User.mfa_*
├── contracts/           # Phase 1 — full endpoint additions
├── quickstart.md        # One walkthrough per user story
└── tasks.md             # Phase 2 (/speckit-tasks output)
```

### Source Code

```text
backend/
├── app/
│   ├── api/v1/endpoints/
│   │   ├── admin.py                       # EXPAND: already has stubs; add any missing CRUD
│   │   ├── audit.py                       # NEW: GET /audit (tenant-scoped) + CSV export
│   │   ├── invites.py                     # NEW (P2): POST /users/invite, POST /accept-invite
│   │   ├── usage.py                       # NEW (P2): GET /tenants/current/usage
│   │   ├── mfa.py                         # NEW (P3): enroll/verify/backup-codes
│   │   └── api_keys.py                    # NEW (P3): CRUD for personal keys
│   ├── services/
│   │   ├── audit_service.py               # NEW: read/filter audit_logs for tenant
│   │   ├── mailer.py                      # NEW (P2): SMTP wrapper + templates
│   │   ├── invite_service.py              # NEW (P2): create/accept, token lifecycle
│   │   ├── usage_service.py               # NEW (P2): compute current usage per metric
│   │   ├── limit_enforcer.py              # NEW (P2): decorator + helpers for plan limits
│   │   ├── mfa_service.py                 # NEW (P3): TOTP enroll/verify, backup-code mgmt
│   │   └── api_key_service.py             # NEW (P3): key hashing, scope checks
│   ├── models/
│   │   ├── invite.py                      # NEW (P2)
│   │   └── api_key.py                     # NEW (P3)
│   ├── schemas/
│   │   ├── admin.py                       # EXPAND
│   │   ├── audit.py                       # NEW
│   │   ├── invite.py                      # NEW (P2)
│   │   ├── usage.py                       # NEW (P2)
│   │   ├── mfa.py                         # NEW (P3)
│   │   └── api_key.py                     # NEW (P3)
│   ├── core/
│   │   ├── deps.py                        # MODIFY: add require_super_admin dep
│   │   └── limits.py                      # NEW (P2): central limit rules + checks
│   └── alembic/versions/
│       ├── <ts>_add_invites_table.py      # P2
│       └── <ts>_add_api_keys_and_mfa.py   # P3
│
frontend/
├── src/
│   ├── app/
│   │   ├── admin/
│   │   │   ├── page.tsx                   # MODIFY: real dashboard stats (currently shallow)
│   │   │   ├── tenants/page.tsx           # MODIFY: list + create/edit drawer
│   │   │   ├── tenants/[id]/page.tsx      # EXISTS: confirm working, polish
│   │   │   └── users/page.tsx             # MODIFY: real approve/deactivate actions
│   │   └── [tenant]/settings/
│   │       ├── audit/page.tsx             # NEW: audit log viewer
│   │       ├── usage/page.tsx             # NEW (P2): usage cards
│   │       ├── security/page.tsx          # NEW (P3): 2FA setup
│   │       └── api-keys/page.tsx          # NEW (P3): API key mgmt
│   ├── app/accept-invite/page.tsx         # NEW (P2): token landing + password set
│   └── components/
│       ├── admin/                         # MODIFY: real tables, real dialogs
│       ├── audit/                         # NEW: filter bar, table, detail drawer
│       ├── settings/invite-user-dialog.tsx  # NEW (P2)
│       └── settings/api-keys/             # NEW (P3)
```

**Structure Decision**: Web app monorepo. The bulk of P1 work is frontend (4 pages), backed by trivial changes on the backend (one new endpoint for audit log + existing admin endpoints). P2/P3 work expands both halves substantially with new services, new tables, and new migrations.

## Phase 0 — Research & Decisions

Seven open questions to resolve in [research.md](./research.md):

1. **Mailer library**: `aiosmtplib` vs `fastapi-mail` vs stdlib `smtplib` in a thread. Decision: `aiosmtplib` — async-native, small, no extras.
2. **Invite token storage**: store raw in DB vs store hash + send raw once. Decision: hash in DB (same pattern we'll use for API keys).
3. **Invite TTL**: 7 days vs 30 days. Decision: 7 days per SaaS norms; admin can resend.
4. **Plan-limit enforcement location**: FastAPI dependency vs service-layer function. Decision: dependency on the endpoint, centralised in `core/limits.py`.
5. **TOTP library**: `pyotp` (mature, tiny, no deps). Decision: pyotp.
6. **API-key format**: `lucent_<32-char-base62>` stored as SHA-256 hash. Decision: yes, same pattern as GitHub PATs.
7. **Audit log retention**: 1 year rolling delete vs indefinite. Decision: 1 year default, configurable via `TENANT_AUDIT_RETENTION_DAYS`.

## Phase 1 — Design Artifacts

- **[data-model.md](./data-model.md)** — schema diffs for Invite, ApiKey, User.status extension, User.mfa_*, plus the augmented User response shape.
- **[contracts/api-contracts.md](./contracts/api-contracts.md)** — full endpoint additions: `/audit`, `/users/invite`, `/accept-invite`, `/tenants/current/usage`, `/mfa/*`, `/api-keys/*`.
- **[quickstart.md](./quickstart.md)** — manual verification walkthrough per user story.

## Complexity Tracking

| Aspect | Decision |
|--------|----------|
| New backend services | 6 (P1: 1, P2: 4, P3: 2) — each single-responsibility; keeps the endpoints thin. |
| New DB tables | 2 (P2: invites, P3: api_keys). User table gains 2 nullable columns in P3. |
| New external dependencies | P1: 0. P2: `aiosmtplib`. P3: `pyotp`. All are pure-Python and small. |
| Breaking API changes | None — all additions. Existing clients unaffected. |
| Migration risk | Alembic autogenerate + review; no data backfill required. |
