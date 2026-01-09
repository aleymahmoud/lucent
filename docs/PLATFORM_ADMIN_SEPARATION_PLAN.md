# Platform Admin Separation Implementation Plan

## Overview

Separating platform administrators from tenant users into distinct authentication flows and database tables.

## Architecture

### Two Separate Authentication Systems:

| System | Table | Login URL | Dashboard URL | Token Key |
|--------|-------|-----------|---------------|-----------|
| Platform Admin | `platform_admins` | `/lucent/login` | `/lucent/admin` | `platform_token` |
| Tenant User | `users` | `/lucent/{tenant}/login` | `/lucent/{tenant}/dashboard` | `token` |

### Key Principles:
1. Platform admins have NO access to tenant dashboards by default
2. To access a tenant, a platform admin must have a separate user account in that tenant
3. Tenant admins can only manage users within their tenant
4. Password resets in tenant context only affect tenant user table

---

## Completed Tasks

### Backend

1. **Created `platform_admins` table model** (`backend/app/models/platform_admin.py`)
   - Separate table for platform administrators
   - Fields: id, email, password_hash, full_name, is_active, timestamps

2. **Created platform admin auth endpoints** (`backend/app/api/v1/endpoints/platform_auth.py`)
   - `POST /api/v1/platform/login` - Platform admin login
   - `GET /api/v1/platform/me` - Get current platform admin info

3. **Updated dependencies** (`backend/app/core/deps.py`)
   - Added `get_current_platform_admin` dependency
   - Token now includes `type: "platform_admin"` to distinguish

4. **Updated admin endpoints** (`backend/app/api/v1/endpoints/admin.py`)
   - Changed from `get_current_super_admin` to `get_current_platform_admin`
   - Removed `is_super_admin` references from responses

5. **Created Alembic migration** (`backend/alembic/versions/fe0abdbaa869_...`)
   - Creates `platform_admins` table
   - Migrates existing super admins to new table
   - Removes `is_super_admin` column from `users` table

6. **Updated User model** (`backend/app/models/user.py`)
   - Removed `SUPER_ADMIN` from `UserRole` enum
   - Removed `is_super_admin` column

### Frontend

7. **Updated platform login page** (`frontend/src/app/(auth)/login/page.tsx`)
   - Dark theme with red accent (indicates admin)
   - Calls `/api/v1/platform/login`
   - Stores `platform_token` and `platform_admin` in localStorage
   - Redirects to `/admin`

8. **Created tenant login page** (`frontend/src/app/[tenant]/login/page.tsx`)
   - Light theme with blue accent
   - Validates tenant exists before showing form
   - Verifies user belongs to the tenant
   - Redirects to `/{tenant}/dashboard`

9. **Updated admin layout** (`frontend/src/app/(admin)/layout.tsx`)
   - Uses `platform_token` instead of `token`
   - Removed "Back to App" button
   - Separate auth check from tenant AuthContext

10. **Updated AuthContext** (`frontend/src/contexts/AuthContext.tsx`)
    - Removed `is_super_admin` field
    - Added `tenantSlug` to context
    - Logout redirects to tenant login page

---

## Remaining Tasks

### Backend Tasks

- [ ] **Run migrations**
  ```bash
  cd backend
  alembic upgrade head
  ```

- [ ] **Update auth.py schemas** - Remove `is_super_admin` from `UserResponse`
  - File: `backend/app/schemas/auth.py`
  - Remove `is_super_admin` field from UserResponse class

- [ ] **Update auth.py endpoints** - Remove `is_super_admin` references
  - File: `backend/app/api/v1/endpoints/auth.py`
  - Update `build_user_response` helper to not include `is_super_admin`
  - Remove any `is_super_admin` checks in login/register/me endpoints

- [ ] **Update tenant auth endpoint** - Add tenant validation
  - File: `backend/app/api/v1/endpoints/auth.py`
  - Login should verify user belongs to the requesting tenant (via header or path param)
  - Consider adding `tenant_slug` parameter to login endpoint

- [ ] **Create password reset endpoints for both systems**
  - Platform admin password reset (`/api/v1/platform/reset-password`)
  - Tenant user password reset (`/api/v1/auth/reset-password`)

- [ ] **Update users.py endpoint** - Remove `is_super_admin` references
  - File: `backend/app/api/v1/endpoints/users.py`
  - Check if any code references `is_super_admin`

### Frontend Tasks

- [ ] **Update Sidebar** - Remove Super Admin link
  - File: `frontend/src/components/layout/Sidebar.tsx`
  - Remove `is_super_admin` check and Super Admin link (lines 117-132)
  - Remove `Shield` import if no longer needed

- [ ] **Update API client** - Tenant-specific 401 redirect
  - File: `frontend/src/lib/api/client.ts`
  - 401 should redirect to `/{tenant}/login` not `/lucent/login`
  - Need to get tenant from current URL or stored user

- [ ] **Update tenant layout** - Protect tenant routes
  - File: `frontend/src/app/[tenant]/layout.tsx`
  - Check user's `tenant_slug` matches URL tenant
  - Redirect to correct tenant login if mismatch

- [ ] **Create tenant register page** (`/lucent/{tenant}/register`)
  - File: `frontend/src/app/[tenant]/register/page.tsx`
  - Request access to a specific tenant
  - Form: email, password, full_name
  - Creates user with `is_approved: false`

- [ ] **Update home page redirect**
  - File: `frontend/src/app/page.tsx`
  - Currently redirects to `/login` (platform admin)
  - Consider showing a landing page or tenant selector

- [ ] **Update or remove old register page**
  - File: `frontend/src/app/(auth)/register/page.tsx`
  - Either remove or repurpose for tenant selection

- [ ] **Update admin dashboard pages** - Use platform auth
  - Files: `frontend/src/app/(admin)/admin/*.tsx`
  - Ensure API calls use `platform_token` header
  - Update any `useAuth()` calls to use platform admin state

- [ ] **Build and test**
  ```bash
  cd frontend
  npm run build
  ```

### Database Tasks

- [ ] **Seed platform admin** (after migration)
  ```bash
  cd backend
  python -c "
  import asyncio
  import bcrypt
  from app.db.database import async_session_maker
  from app.models import PlatformAdmin

  async def seed():
      async with async_session_maker() as db:
          admin = PlatformAdmin(
              email='admin@lucent.com',
              password_hash=bcrypt.hashpw(b'Admin123!', bcrypt.gensalt()).decode(),
              full_name='Platform Admin',
              is_active=True
          )
          db.add(admin)
          await db.commit()
          print('Platform admin created')

  asyncio.run(seed())
  "
  ```

- [ ] **Verify migration** - Check data integrity after migration
  - Confirm `platform_admins` table exists
  - Confirm existing super admin was migrated
  - Confirm `is_super_admin` column removed from `users`

---

## URL Structure Summary

```
/lucent                        → Landing or redirect
/lucent/login                  → Platform admin login
/lucent/admin                  → Platform admin dashboard
/lucent/admin/tenants          → Manage tenants
/lucent/admin/users            → View all users

/lucent/{tenant}/login         → Tenant user login
/lucent/{tenant}/register      → Request access to tenant
/lucent/{tenant}/dashboard     → Tenant dashboard
/lucent/{tenant}/settings/*    → Tenant settings
```

---

## Testing Checklist

- [ ] Platform admin can login at `/lucent/login`
- [ ] Platform admin can access `/lucent/admin`
- [ ] Platform admin CANNOT access tenant dashboards
- [ ] Tenant user can login at `/lucent/{tenant}/login`
- [ ] Tenant user CANNOT login to wrong tenant
- [ ] Tenant user CANNOT access platform admin
- [ ] Tenant admin can manage users in their tenant
- [ ] Tenant admin CANNOT see other tenants' users
- [ ] Logout redirects to correct login page

---

## Files Modified

### Backend
- `backend/app/models/platform_admin.py` (NEW)
- `backend/app/models/__init__.py`
- `backend/app/models/user.py`
- `backend/app/api/v1/endpoints/platform_auth.py` (NEW)
- `backend/app/api/v1/endpoints/admin.py`
- `backend/app/api/v1/api.py`
- `backend/app/core/deps.py`
- `backend/app/schemas/admin.py`
- `backend/alembic/versions/fe0abdbaa869_...py` (NEW)

### Frontend
- `frontend/src/app/(auth)/login/page.tsx`
- `frontend/src/app/[tenant]/login/page.tsx` (NEW)
- `frontend/src/app/(admin)/layout.tsx`
- `frontend/src/contexts/AuthContext.tsx`
- `frontend/src/components/layout/Sidebar.tsx` (needs update)
- `frontend/src/lib/api/client.ts` (needs update)
