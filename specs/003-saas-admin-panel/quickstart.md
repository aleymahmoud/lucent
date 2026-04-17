# Quickstart — Manual Verification

**Feature**: SaaS Admin Panel
**Plan**: [plan.md](./plan.md)

One walkthrough per user story. Walkthroughs 1-4 are the P1 tier (shipping first).

## Prerequisites

1. Backend + frontend running (`pm2 restart lucent-backend lucent-frontend`).
2. At least one super-admin account seeded in the DB.
3. At least 2 tenants and 5 users across them, with at least 1 pending-approval user.

---

## Walkthrough 1 — Manage tenants (US1, P1)

Steps:
1. Log in as super-admin. Navigate to `/admin/tenants`.
2. Click "Create Tenant"; enter name "Walkthrough Co", slug "walkthrough", plan "starter", max_users 5.
3. Confirm the new row appears with status "Active".
4. Click the row to open the detail drawer. Change plan to "pro". Save.
5. Click "Deactivate". Confirm the destructive-action dialog.
6. Confirm the row shows "Inactive" status and is filtered-out by default.

**Expected**: All four actions complete without errors. Backend audit log has 4 entries: tenant.create, tenant.update, tenant.deactivate.

---

## Walkthrough 2 — Approve / deactivate platform users (US2, P1)

Steps:
1. As super-admin, visit `/admin/users`.
2. Confirm the table lists users from multiple tenants (tenant column visible).
3. Find a user with status "pending_approval"; click "Approve".
4. Confirm the status flips to "active".
5. Log out, log in as that user — login succeeds.
6. Back as super-admin, find the same user and click "Deactivate".
7. Confirm any open sessions for that user return 401 on the next request.

**Expected**: Approve + deactivate work end-to-end. Deactivated user cannot log in.

---

## Walkthrough 3 — Platform dashboard (US3, P1)

Steps:
1. As super-admin, visit `/admin`.
2. Confirm four cards: Tenants, Users, Pending Approvals, Forecasts (24h).
3. Verify the numbers match `/admin/tenants` length, `/admin/users` length, filtered pending count, and a DB query on forecast_history.
4. Click the "Pending Approvals" card — lands on `/admin/users?status=pending_approval`.

**Expected**: Dashboard reads from `/admin/stats`; card clicks navigate with the right filters.

---

## Walkthrough 4 — Audit log viewer (US4, P1)

Steps:
1. As tenant admin, visit `/settings/audit`.
2. Confirm a paginated table renders with at least 50 events scoped to your tenant.
3. Filter by action=`login`; confirm rows narrow.
4. Set date range to "last 7 days"; confirm further narrowing.
5. Click a row; confirm detail panel shows IP, user-agent, and the `details` JSON.
6. Click "Export CSV"; confirm a CSV downloads with exactly the currently-filtered rows.

**Expected**: Filters are AND-combined. CSV export respects the same filters.

---

## Walkthrough 5 — Invite a user by email (US5, P2) [not in MVP]

Steps:
1. As tenant admin at `/settings/users`, click "Invite User".
2. Enter email, role=analyst, pick a group. Submit.
3. If SMTP is configured, confirm an email arrives at the target address with a link.
4. If SMTP is not configured, confirm the dialog shows "Copy link" with the raw URL.
5. Open the link in an incognito window. Set a password. Confirm you land on the dashboard as the new user.
6. As admin, try to accept the same link again — expect "already used" error.

---

## Walkthrough 6 — Email flows (US6, P2) [not in MVP]

Steps:
1. On the login page, click "Forgot password". Enter an existing email.
2. Confirm a reset email arrives within 30s.
3. Open link, set new password, log in.

---

## Walkthrough 7 — Usage page (US7, P2) [not in MVP]

Steps:
1. As tenant admin, visit `/settings/usage`.
2. Confirm cards for users, forecasts-this-month, storage.
3. Confirm progress bars color-shift to amber above 80% and red above 100%.

---

## Walkthrough 8 — Plan-limit enforcement (US8, P2) [not in MVP]

Steps:
1. Super-admin sets max_users=3 for a tenant.
2. Tenant admin creates 3 users — all succeed.
3. Tenant admin invites a 4th user — fails with 402 and a message about the limit.
4. Super-admin bumps max_users=5.
5. 4th user creation now succeeds.

---

## Walkthrough 9 — MFA enrollment (US9, P3) [not in MVP]

Steps:
1. Go to `/settings/security`. Click "Enable 2FA".
2. Scan QR with an authenticator app; enter the 6-digit code.
3. Confirm 10 backup codes are shown.
4. Log out, log back in — prompted for TOTP after password.
5. Use a backup code instead of TOTP — succeeds, that code is consumed.

---

## Walkthrough 10 — API keys (US10, P3) [not in MVP]

Steps:
1. Go to `/settings/api-keys`. Click "Create API Key".
2. Enter name "Test", scopes=["read"]. Submit.
3. Copy the displayed key. Confirm key_prefix is visible after closing the dialog.
4. Call `GET /forecast/methods` with `Authorization: Bearer <key>` from curl — succeeds.
5. Revoke the key. Call again — returns 401.
