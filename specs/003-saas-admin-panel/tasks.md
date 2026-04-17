# Tasks: SaaS Admin Panel

**Input**: Design documents from `/specs/003-saas-admin-panel/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/)

**Tests**: pytest for each new service module (`invite_service`, `limit_enforcer`, `mfa_service`, `api_key_service`, `audit_service`). Manual walkthroughs per [quickstart.md](./quickstart.md).

**Organization**: Tasks grouped by user story with explicit priority. MVP is the P1 tier (US1–US4). P2 and P3 tasks are defined now and can be picked up later without re-planning.

## Format: `[TaskID] [P?] [Story?] Description with file path`

---

## Phase 1: Setup (P1 — no schema changes)

- [ ] T001 Add `AuditEventResponse` and `AuditListResponse` schemas to `backend/app/schemas/audit.py`
- [ ] T002 [P] Extend `backend/app/core/deps.py` with `require_super_admin` and `require_tenant_admin` dependencies
- [ ] T003 [P] Add `AuditEvent` TypeScript type to `frontend/src/types/index.ts`

---

## Phase 2: US1 — Platform admin: tenant management (P1)

- [ ] T004 [US1] Audit existing `/admin/tenants` endpoints in `backend/app/api/v1/endpoints/admin.py`; patch missing fields or 403 role checks
- [ ] T005 [US1] Rewrite `frontend/src/app/admin/tenants/page.tsx` to a table with create/edit/deactivate actions calling the real endpoints
- [ ] T006 [US1] Create `frontend/src/app/admin/tenants/[id]/page.tsx` detail drawer/page with edit + limit adjustment
- [ ] T007 [P] [US1] Shadcn dialog component for "Create Tenant" in `frontend/src/components/admin/create-tenant-dialog.tsx`

---

## Phase 3: US2 — Platform admin: users (P1)

- [ ] T008 [US2] Audit existing `/admin/users/*` endpoints; ensure approve + deactivate flip status correctly and invalidate sessions on deactivate
- [ ] T009 [US2] Rewrite `frontend/src/app/admin/users/page.tsx` with cross-tenant table, approve/deactivate buttons, pending-filter URL param
- [ ] T010 [P] [US2] Status badge component `frontend/src/components/admin/user-status-badge.tsx`

---

## Phase 4: US3 — Platform dashboard (P1)

- [ ] T011 [US3] Confirm `/admin/stats` returns the 4 metrics; add `forecasts_last_24h` if missing
- [ ] T012 [US3] Rewrite `frontend/src/app/admin/page.tsx` with 4 stat cards + recent-activity panel + click-through navigation

---

## Phase 5: US4 — Audit log viewer (P1)

- [ ] T013 [US4] Create `backend/app/services/audit_service.py` with `list_events(tenant_id, filters, page, page_size)` + CSV export
- [ ] T014 [US4] Create `backend/app/api/v1/endpoints/audit.py` with GET `/audit` (paginated, filterable) + GET `/audit/export` (CSV)
- [ ] T015 [US4] Register the audit router in `backend/app/api/v1/api.py`
- [ ] T016 [US4] Create `frontend/src/app/[tenant]/settings/audit/page.tsx` with filter bar, paginated table, detail drawer, export button
- [ ] T017 [P] [US4] Create `frontend/src/components/audit/audit-table.tsx` reusable table
- [ ] T018 [P] [US4] Create `frontend/src/components/audit/event-detail-drawer.tsx` JSON details display
- [ ] T019 [P] [US4] Add navigation entry for "Audit Log" in the tenant settings sidebar

---

## Phase 6: US5 — User invites (P2, not in MVP)

- [ ] T020 [US5] Alembic migration: new `invites` table + `users.status` enum value
- [ ] T021 [US5] Create `backend/app/models/invite.py`
- [ ] T022 [US5] Create `backend/app/services/invite_service.py` (create, accept, resend, revoke, expire)
- [ ] T023 [P] [US5] pytest suite `backend/tests/services/test_invite_service.py` — unique hashes, expired rejection, double-accept rejection
- [ ] T024 [US5] Create `backend/app/api/v1/endpoints/invites.py` with POST `/users/invite`, GET `/users/invites`, DELETE `/users/invites/{id}`, POST `/users/invites/{id}/resend`, POST `/accept-invite`
- [ ] T025 [US5] Frontend: "Invite User" dialog component, mounted on `/settings/users` alongside "Create User"
- [ ] T026 [US5] Frontend: `/accept-invite?token=...` landing page with password-set form

---

## Phase 7: US6 — Email notifications (P2, not in MVP)

- [ ] T027 [US6] Create `backend/app/services/mailer.py` (aiosmtplib wrapper; graceful no-op when SMTP_HOST not set)
- [ ] T028 [US6] Plain-text + HTML templates for: invite, password reset, account approved
- [ ] T029 [US6] Wire invite_service and password-reset flow to mailer.send()
- [ ] T030 [P] [US6] pytest with mocked SMTP: verify message body, From/To, subject

---

## Phase 8: US7 — Usage display (P2, not in MVP)

- [ ] T031 [US7] Create `backend/app/services/usage_service.py` (compute current users, forecasts-this-month, storage)
- [ ] T032 [US7] Create GET `/tenants/current/usage` endpoint
- [ ] T033 [US7] Create `frontend/src/app/[tenant]/settings/usage/page.tsx` with 3 progress-bar cards + color thresholds

---

## Phase 9: US8 — Plan-limit enforcement (P2, not in MVP)

- [ ] T034 [US8] Create `backend/app/core/limits.py` with `require_user_quota`, `require_forecast_quota` FastAPI dependencies
- [ ] T035 [US8] Attach `require_user_quota` to POST `/users` and POST `/users/invite`
- [ ] T036 [US8] Attach `require_forecast_quota` to POST `/forecast/run` and POST `/forecast/batch`
- [ ] T037 [P] [US8] pytest integration: set max_users=2, create 3 users, assert 402 on the 3rd
- [ ] T038 [US8] Add `X-Usage-Remaining` response header when success

---

## Phase 10: US9 — MFA (P3, not in MVP)

- [ ] T039 [US9] Alembic migration: add `mfa_secret`, `mfa_enabled`, `mfa_backup_codes` to users
- [ ] T040 [US9] Create `backend/app/services/mfa_service.py` (enrol, verify, consume_backup_code, disable)
- [ ] T041 [P] [US9] pytest for mfa_service
- [ ] T042 [US9] Endpoints: POST `/mfa/enroll`, POST `/mfa/verify`, POST `/mfa/disable`, POST `/auth/mfa/challenge`
- [ ] T043 [US9] Modify `/auth/login` to return 202 `require_mfa=true` when enabled
- [ ] T044 [US9] Frontend: `/settings/security` page with QR code display + backup code reveal
- [ ] T045 [US9] Frontend: login page challenge screen (enter 6-digit code) + backup-code fallback

---

## Phase 11: US10 — API Keys (P3, not in MVP)

- [ ] T046 [US10] Alembic migration: new `api_keys` table
- [ ] T047 [US10] Create `backend/app/models/api_key.py`
- [ ] T048 [US10] Create `backend/app/services/api_key_service.py` (create, list, revoke, authenticate)
- [ ] T049 [P] [US10] pytest suite for api_key_service
- [ ] T050 [US10] Endpoints: GET/POST/DELETE `/api-keys`
- [ ] T051 [US10] Extend `get_current_user` dependency to accept Bearer tokens that match `api_keys.key_hash`
- [ ] T052 [US10] Frontend: `/settings/api-keys` page with create/revoke flow; copy-once dialog

---

## Phase 12: Polish & commit (final phase)

- [ ] T053 [P] Register new shared utilities in `docs/shared-registry.md` (audit_service, mailer, invite_service, usage_service, limit_enforcer, mfa_service, api_key_service)
- [ ] T054 [P] Manual run of all quickstart walkthroughs for P1
- [ ] T055 Frontend build + PM2 restart + smoke test
- [ ] T056 Commit scoped changes; leave for user to push

---

## Dependencies

### Phase-level
- Phase 1 (Setup) blocks Phases 2–5 (P1 work)
- Phases 2–5 (P1) are independent of each other — any can ship first
- Phase 6 (invite service) blocks Phase 7 (email hookup)
- Phase 8 (usage) is independent; Phase 9 (limits) uses its metrics
- Phases 10 and 11 (MFA, API keys) are independent

### Task-level
- T020 (migration) → T021–T024 (invite service + endpoints)
- T027 (mailer) → T029 (wiring)
- T031 (usage_service) → T032 (endpoint)
- T034 (limit helpers) → T035, T036 (apply to endpoints)
- T039 (migration) → T040–T042 (MFA)
- T046 (migration) → T047–T051 (api keys)

### Parallel opportunities
- Phase 1: T002, T003 [P]
- Phase 2: T007 [P]
- Phase 3: T010 [P]
- Phase 5: T017, T018, T019 [P]
- P2/P3 phases: many [P] tests and frontend components

---

## MVP Scope (ships NOW)

**Phases 1 through 5** = US1 + US2 + US3 + US4 = ~19 tasks.

Delivers:
- Tenant management UI
- Platform user approve/deactivate UI
- Platform dashboard
- Audit log viewer

Everything else (Phases 6–11) is specified in full and can be shipped incrementally when needed — no further planning required.

---

## Task Count Summary

| Phase | Tasks | Priority | In MVP |
|-------|-------|----------|--------|
| 1. Setup | 3 | P1 | Yes |
| 2. US1 tenants | 4 | P1 | Yes |
| 3. US2 users | 3 | P1 | Yes |
| 4. US3 dashboard | 2 | P1 | Yes |
| 5. US4 audit log | 7 | P1 | Yes |
| 6. US5 invites | 7 | P2 | — |
| 7. US6 email | 4 | P2 | — |
| 8. US7 usage | 3 | P2 | — |
| 9. US8 limits | 5 | P2 | — |
| 10. US9 MFA | 7 | P3 | — |
| 11. US10 API keys | 7 | P3 | — |
| 12. Polish | 4 | — | Yes (partial) |
| **Total** | **56** | | **~22 in MVP** |
