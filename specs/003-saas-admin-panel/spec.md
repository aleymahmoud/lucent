# Feature Specification: SaaS Admin Panel

**Feature Branch**: `003-saas-admin-panel`
**Created**: 2026-04-17
**Status**: Draft
**Input**: User description: "SaaS admin panel — expose stubbed platform admin UIs, audit log, user invites, email, usage quotas, MFA, API keys"

## Background Context

The old R Shiny app has no Settings or Admin area at all — it's a single-user tool. LUCENT, as a multi-tenant SaaS, already ships several tenant-level admin pages (`/settings/users`, `/settings/groups`, `/settings/connectors`, `/settings/branding`) backed by working endpoints.

What's missing is:

1. **Platform-level admin UI** — super-admin endpoints (`/admin/tenants`, `/admin/users`, `/admin/stats`) exist on the backend but have no frontend pages.
2. **Audit log viewer** — the `audit_logs` table is written to but no page reads from it.
3. **User onboarding** — no invite flow; admins create users by setting passwords directly.
4. **Email notifications** — no backend mailer; password resets, invites, approvals are surfaced in-UI only.
5. **Usage enforcement** — tenants have a `limits` JSON column (max users, forecast horizon, rate limits) but no UI shows current consumption, and enforcement is uneven.
6. **Multi-factor auth** — no second-factor option.
7. **API keys** — no programmatic access mechanism.

This feature delivers all of the above. Priorities are staged so the highest-leverage pieces (platform admin UIs + audit log) ship first and the later tiers (invites/email, quotas, MFA, API keys) layer on incrementally.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Super admin manages tenants (Priority: P1)

As a platform super-admin, I want a web page to create, view, edit, and deactivate tenants so I don't have to call `/admin/tenants` with curl.

**Why this priority**: The backend CRUD already works. Without a UI, onboarding a new tenant requires a developer. This is the single biggest daily friction point for the platform operator.

**Independent Test**: Navigate to `/admin/tenants`, click "Create Tenant", fill in name + slug + plan, submit. Confirm the tenant appears in the list. Then edit it, toggle "active" off, confirm the status badge updates.

**Acceptance Scenarios**:

1. **Given** I am logged in as a super-admin, **When** I visit `/admin/tenants`, **Then** I see a table of all tenants with columns: name, slug, plan, users, created, status.
2. **Given** the list is empty, **When** I click "Create Tenant", **Then** a dialog opens with fields for name, slug, plan tier, and seat limit; submitting saves via `POST /admin/tenants` and the new row appears.
3. **Given** I click a tenant row, **When** the detail drawer opens, **Then** I can edit name/plan/limits and toggle `is_active`; changes save via `PATCH /admin/tenants/{id}`.
4. **Given** I click "Delete", **When** I confirm the destructive-action dialog, **Then** the tenant is soft-deleted (`is_active=false`) via `DELETE /admin/tenants/{id}`.

---

### User Story 2 — Super admin manages platform users (Priority: P1)

As a platform super-admin, I want a cross-tenant user list with approve/deactivate actions, so I can moderate the whole platform from one page.

**Why this priority**: Same logic as US1 — backend endpoints exist; without a UI, user approval (which blocks login) requires a developer.

**Independent Test**: Navigate to `/admin/users`. Confirm the list includes users across every tenant. Find a pending user, click "Approve", confirm the status flips and the user can log in.

**Acceptance Scenarios**:

1. **Given** I am a super-admin, **When** I visit `/admin/users`, **Then** I see every user with tenant, email, role, status, created date — paginated with search.
2. **Given** a user has `status=pending_approval`, **When** I click "Approve", **Then** the user becomes `active` via `POST /admin/users/{id}/approve`.
3. **Given** an active user, **When** I click "Deactivate", **Then** the user becomes `inactive` via `POST /admin/users/{id}/deactivate` and any outstanding sessions are invalidated.

---

### User Story 3 — Super admin sees platform-wide stats (Priority: P1)

As a platform super-admin, I want a dashboard showing total tenants, total users, pending approvals, and forecasts run in the last 24 hours so I can see the health of the platform at a glance.

**Why this priority**: Fast situational awareness. Reads the existing `/admin/stats` endpoint.

**Independent Test**: Navigate to `/admin`. Confirm four large stat cards render with non-zero values and a recent-activity panel shows the last 10 forecasts across all tenants.

**Acceptance Scenarios**:

1. **Given** I am a super-admin, **When** I visit `/admin`, **Then** I see cards for "Tenants", "Users", "Pending Approvals", "Forecasts (24h)" with counts.
2. **Given** I click a card, **When** I land on the corresponding list page, **Then** the filter matches the card (e.g., "Pending Approvals" opens `/admin/users?status=pending`).

---

### User Story 4 — Admin views audit log (Priority: P1)

As a tenant admin, I want to see a filterable list of security-relevant actions (logins, role changes, connector credentials updated, forecasts deleted) so I can investigate suspicious activity and satisfy compliance requirements.

**Why this priority**: The `audit_logs` table is already populated on most sensitive actions. Reading it requires no new write paths, just a new endpoint + UI.

**Independent Test**: Navigate to `/settings/audit`. Confirm a table shows at least the last 50 events with columns: timestamp, user, action, resource, IP. Filter by user or action type and confirm rows narrow.

**Acceptance Scenarios**:

1. **Given** I am a tenant admin, **When** I visit `/settings/audit`, **Then** a paginated table renders with events for my tenant only.
2. **Given** the filter controls are visible, **When** I select an action type (e.g., "login") and a date range, **Then** the table narrows via `GET /audit?action=login&from=...&to=...`.
3. **Given** I click a row, **When** the detail panel opens, **Then** I see the full JSON payload (user_id, request metadata, resource_id, IP, user-agent).
4. **Given** I click "Export CSV", **When** the request completes, **Then** a CSV of the currently filtered rows downloads.

---

### User Story 5 — Admin invites new users by email (Priority: P2)

As a tenant admin, I want to send an invitation link by email rather than setting a password for the user directly, so onboarding is a self-service flow.

**Why this priority**: Current flow forces the admin to ship credentials out-of-band (Slack/chat). An invite link eliminates that risk and is a standard SaaS expectation.

**Independent Test**: From `/settings/users`, click "Invite User". Enter email + role. A single-use invite link is emailed (or, if email not configured, shown in a "copy link" modal). Paste the link in an incognito window, sign up, confirm the new user lands in the right tenant with the right role.

**Acceptance Scenarios**:

1. **Given** I am a tenant admin, **When** I click "Invite User", **Then** a form asks for email, role, and optional group; submit calls `POST /users/invite`.
2. **Given** email is configured, **When** the invite is created, **Then** the invitee receives an email with a unique `/accept-invite?token=...` link that expires in 7 days.
3. **Given** email is not configured, **When** the invite is created, **Then** the link is shown in a dialog with "Copy link" so the admin can share it manually.
4. **Given** the invitee opens the link, **When** they set a password, **Then** their account is created with the invited role and they are auto-logged-in.
5. **Given** the token has expired or been used, **When** the invitee opens it, **Then** they see a clear error with "request a new invite".

---

### User Story 6 — Email notifications for key events (Priority: P2)

As a user, I want email notifications for password reset, invitation, and account approval so I don't have to chase the admin.

**Why this priority**: Directly enables US5 (invite) and improves existing flows (password reset). Also required for audit reasons — an email log is harder to repudiate than an in-UI toast.

**Independent Test**: Trigger a password reset from the login page. Confirm an email arrives at the configured address with a reset link. Open the link, set a new password, log in successfully.

**Acceptance Scenarios**:

1. **Given** the SMTP backend is configured, **When** a password reset is requested, **Then** an email with a reset link is sent within 30 seconds.
2. **Given** a user's account is approved, **When** the admin approves, **Then** the user receives an email saying "your account is now active".
3. **Given** SMTP is not configured, **When** any email trigger fires, **Then** the action still succeeds and a warning is logged (emails are best-effort).

---

### User Story 7 — Admin sees usage vs. tenant limits (Priority: P2)

As a tenant admin, I want to see how close we are to our plan limits (users, forecasts per month, data storage) so I know when to upgrade or trim usage.

**Why this priority**: Tenants have a `limits` JSON column but no visibility. As the platform grows this becomes more important — without it, users only discover limits by hitting them.

**Independent Test**: From `/settings`, open a "Usage" section. Confirm progress bars show current / limit for at least: users (e.g., 7/10), forecasts this month (e.g., 34/100), data storage MB.

**Acceptance Scenarios**:

1. **Given** I am a tenant admin, **When** I visit `/settings/usage`, **Then** I see a card per metric with current value, limit, and a progress bar.
2. **Given** usage is above 80% of a limit, **When** the page renders, **Then** the bar is amber with a warning message.
3. **Given** usage exceeds a limit, **When** a user tries to perform the blocked action (e.g., create the 11th user on a 10-seat plan), **Then** the action fails with a clear error referencing the limit.

---

### User Story 8 — Platform operator enforces plan limits (Priority: P2)

As a platform super-admin, I want plan limits to be enforced server-side so tenants can't exceed their subscription tier.

**Why this priority**: Without enforcement, limits are cosmetic. The limits column already exists; we need the middleware / service checks.

**Independent Test**: Set a tenant's `max_users=3`. Try to create a 4th user — fails with HTTP 402 (Payment Required) or 403 (Forbidden) and a descriptive message.

**Acceptance Scenarios**:

1. **Given** a tenant has `max_users=N`, **When** the Nth+1 user is created, **Then** the create endpoint returns 402 with `{"detail": "Plan limit reached: maximum N users. Upgrade your plan to add more."}`.
2. **Given** a tenant has `max_forecasts_per_month=M`, **When** the M+1'th forecast is submitted in the current month, **Then** the forecast endpoint returns 402.
3. **Given** a tenant is approaching but not at a limit, **When** any limited action succeeds, **Then** the response includes a `X-Usage-Remaining` header for client-side warnings.

---

### User Story 9 — User enables MFA (Priority: P3)

As a user handling sensitive forecasts, I want to enable two-factor authentication (TOTP) on my account.

**Why this priority**: Security hardening. P3 because it's additive and doesn't block anything.

**Acceptance Scenarios**:

1. **Given** I am logged in, **When** I go to `/settings/security` and click "Enable 2FA", **Then** a QR code is shown for an authenticator app (Google/1Password/Authy).
2. **Given** I scan the code and enter the 6-digit code, **When** I submit, **Then** 2FA is enabled and 10 backup codes are shown once.
3. **Given** 2FA is enabled, **When** I log in, **Then** after password I am prompted for a TOTP code.
4. **Given** I lose my device, **When** I enter a backup code instead, **Then** I log in and that code is consumed.

---

### User Story 10 — User creates API keys (Priority: P3)

As a developer user, I want to create scoped API keys so I can call the forecast API from scripts without sharing my password.

**Why this priority**: Programmatic access. P3 because session-token auth already works for the UI.

**Acceptance Scenarios**:

1. **Given** I am logged in, **When** I go to `/settings/api-keys` and click "Create API Key", **Then** I pick a name and scope (read-only / read-write), submit, and the full key is shown ONCE for copying.
2. **Given** a key exists, **When** I revoke it, **Then** subsequent requests with that key return 401.
3. **Given** an API key is used, **When** any endpoint is called with `Authorization: Bearer <api_key>`, **Then** the request succeeds with the scope and tenant of the key.

---

### Edge Cases

- Super-admin logs in to a deactivated tenant's space — blocked with clear message, can re-activate from `/admin/tenants`.
- Invite token accepted twice — second attempt shows "already used" error.
- Audit log fills up — server trims events older than 1 year; admin can export before deletion.
- SMTP credentials rotate — emails fail silently for a period; the first failed delivery logs a warning and sets a flag visible on `/admin`.
- Plan limit is reduced below current usage — existing records keep working; new-creation actions fail until usage drops or plan is upgraded.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST expose `/admin/tenants` list + detail UI with create / edit / deactivate actions backed by existing endpoints.
- **FR-002**: System MUST expose `/admin/users` cross-tenant UI with approve / deactivate actions.
- **FR-003**: System MUST expose `/admin` dashboard with tenant count, user count, pending approvals, and forecasts-in-last-24h cards.
- **FR-004**: System MUST expose `/settings/audit` tenant-scoped audit log viewer with filters and CSV export.
- **FR-005**: System MUST provide an `POST /users/invite` endpoint that creates a single-use invite token and (when configured) sends an email.
- **FR-006**: System MUST provide a `POST /accept-invite` endpoint that exchanges a valid token for an activated user account.
- **FR-007**: System MUST provide an SMTP-backed mailer with send_password_reset, send_invite, and send_approval_notification functions. The mailer MUST fail gracefully when SMTP is not configured.
- **FR-008**: System MUST expose `/settings/usage` showing current vs. limit for users, forecasts per month, and data storage.
- **FR-009**: System MUST enforce `max_users` on `POST /users` and `POST /users/invite`, returning 402 with a descriptive message when exceeded.
- **FR-010**: System MUST enforce `max_forecasts_per_month` on `POST /forecast/run` and `POST /forecast/batch`.
- **FR-011**: System MUST support TOTP 2FA with an enrollment flow, login challenge, and 10 backup codes.
- **FR-012**: System MUST support personal API keys with scopes (read / write) and revocation; keys authenticate via `Authorization: Bearer`.
- **FR-013**: Audit log entries MUST include: timestamp, tenant_id, user_id, action, resource_type, resource_id, IP, user-agent, and request payload (PII-redacted).
- **FR-014**: All admin routes MUST enforce role checks at the endpoint layer: `/admin/*` requires platform super-admin; `/settings/audit` + `/settings/usage` + user/invite/role changes require tenant admin.

### Key Entities

- **Tenant**: already exists; no schema change. UI + route additions only.
- **User**: adds `status` enum extension (adds `pending_invite`), `mfa_secret` (nullable), `mfa_backup_codes` (JSON array).
- **Invite**: new table — `id`, `tenant_id`, `email`, `role`, `token_hash`, `expires_at`, `used_at`, `created_by`.
- **ApiKey**: new table — `id`, `user_id`, `tenant_id`, `name`, `key_hash`, `scopes`, `last_used_at`, `revoked_at`, `created_at`.
- **AuditLog**: already exists; read-only UI.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of the stubbed `/admin/*` endpoints have a matching UI page in production (tenants, users, stats).
- **SC-002**: Audit log viewer returns results in under 500ms for queries scoped to a single tenant over the last 30 days.
- **SC-003**: When SMTP is configured, ≥95% of invite emails are delivered successfully (measured over a 7-day rolling window).
- **SC-004**: User invite acceptance rate — of invites sent, at least 70% are accepted within 7 days.
- **SC-005**: Plan-limit violations on enforced endpoints return HTTP 402 in 100% of over-limit requests.
- **SC-006**: 2FA enrollment completes successfully for 100% of attempts where the user enters a valid TOTP code.
- **SC-007**: API key authentication succeeds on 100% of properly-formed Bearer-token requests with active keys.

## Assumptions

- SMTP credentials will be provided via environment variables (`SMTP_HOST`, `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_FROM`). If not set, email flows degrade gracefully (invite link shown in-UI, password reset link logged).
- The super-admin role already exists in the auth system (spec 001 seeded the auth layer); this feature does not change role semantics.
- Audit log entries are best-effort — if the write fails, the underlying action still succeeds (current behaviour).
- Plan limits are simple integer ceilings; no tiered / gradient pricing logic.
- TOTP uses standard `pyotp` (backend) and any authenticator app on the client side; no custom token delivery.
- API keys are personal (bound to a user), not tenant-shared. Rotation is manual (revoke + recreate).
- The new Invite and ApiKey tables will be added via a normal Alembic migration; no data migration required.
