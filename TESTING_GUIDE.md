# 🧪 Phase 1 Testing Guide

This guide shows you exactly what to expect when testing your LUCENT application.

---

## ✅ Pre-Test Checklist

Make sure both servers are running:

**Backend Server:**
```bash
cd C:\Lucent\backend
python -m uvicorn app.main:app --reload
```
Expected output:
```
✅ Database connection successful
✅ Database initialized
✅ Redis connection established
✅ Redis initialized
Application startup complete.
```

**Frontend Server:**
```bash
cd C:\Lucent\frontend
npm run dev
```
Expected output:
```
✓ Ready in 889ms
- Local: http://localhost:3001
```

---

## 🔍 Test 1: Backend API Documentation

### What to Do:
Open in your browser: **http://localhost:8000/api/v1/docs**

### What You Should See:
![API Docs Interface]

**Swagger UI with these endpoints:**

📁 **Authentication**
- POST `/api/v1/auth/register` - Create new user and tenant
- POST `/api/v1/auth/login` - Login existing user
- GET `/api/v1/auth/me` - Get current user info
- POST `/api/v1/auth/logout` - Logout user

**Each endpoint shows:**
- Request body schema
- Response schema
- Try it out button
- Example values

---

## 🔍 Test 2: Backend Health Check

### What to Do:
Open: **http://localhost:8000/api/v1/health**

### What You Should See:
```json
{
  "status": "healthy",
  "environment": "development",
  "version": "0.1.0"
}
```

---

## 🔍 Test 3: Frontend - Register Page

### What to Do:
1. Open: **http://localhost:3001/lucent/register**

### What You Should See:

**Page Layout:**
```
┌─────────────────────────────────────┐
│                                     │
│    Create an account                │
│    Get started with LUCENT          │
│    forecasting platform             │
│                                     │
│    Full Name                        │
│    [Text Input]                     │
│                                     │
│    Company Name                     │
│    [Text Input]                     │
│                                     │
│    Email                            │
│    [Email Input]                    │
│                                     │
│    Password                         │
│    [Password Input]                 │
│    Must be at least 8 characters    │
│                                     │
│    [Create account] Button          │
│                                     │
│    Already have an account? Sign in │
│                                     │
└─────────────────────────────────────┘
```

**Styling:**
- White card on gray background
- Centered on page
- Clean, modern design
- Blue accents
- Responsive layout

---

## 🔍 Test 4: Registration Flow

### What to Do:
Fill in the registration form:

**Test Data:**
```
Full Name: John Doe
Company Name: Acme Corp
Email: john@acme.com
Password: password123
```

Click **"Create account"**

### What You Should See:

**During Registration:**
- Button changes to "Creating account..."
- Button is disabled
- Form fields are disabled

**On Success:**
- Automatically redirected to: `http://localhost:3001/lucent/dashboard`
- You're now logged in!
- Dashboard shows:
  - Sidebar with navigation
  - Header with user info
  - Stats cards (placeholder data)
  - Recent activity section

**On Error (if email exists):**
- Red error banner appears:
  ```
  Email already registered
  ```

---

## 🔍 Test 5: Frontend - Login Page

### What to Do:
1. Open: **http://localhost:3001/lucent/login**

### What You Should See:

**Page Layout:**
```
┌─────────────────────────────────────┐
│                                     │
│    Sign in to LUCENT                │
│    Enter your email and password    │
│    to access your account           │
│                                     │
│    Email                            │
│    [Email Input]                    │
│                                     │
│    Password                         │
│    [Password Input]                 │
│                                     │
│    [Sign in] Button                 │
│                                     │
│    Don't have an account? Create one│
│                                     │
└─────────────────────────────────────┘
```

**Features:**
- Link to register page (blue underlined)
- Clean, simple form
- Same styling as register page

---

## 🔍 Test 6: Login Flow

### What to Do:
Use the credentials you just created:
```
Email: john@acme.com
Password: password123
```

Click **"Sign in"**

### What You Should See:

**During Login:**
- Button changes to "Signing in..."
- Form fields disabled

**On Success:**
- Redirected to dashboard: `http://localhost:3001/lucent/dashboard`
- Same dashboard view as after registration

**On Error (wrong password):**
- Red error banner:
  ```
  Incorrect email or password
  ```

---

## 🔍 Test 7: Dashboard After Login

### What You Should See:

**Layout:**
```
┌────────┬──────────────────────────────────────┐
│        │  Header                              │
│        │  [Search] [Notifications] [User Menu]│
│ Side   ├──────────────────────────────────────┤
│ bar    │                                      │
│        │  📊 Dashboard                        │
│ - Home │                                      │
│ - Data │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐  │
│ - Prep │  │Total│ │Active│ │Fore-│ │Com- │  │
│ - Fore │  │Data │ │Users│ │casts│ │plete│  │
│ - Res  │  │sets │ │     │ │     │ │Rate │  │
│ - Diag │  └─────┘ └─────┘ └─────┘ └─────┘  │
│ - Set  │                                      │
│        │  Recent Forecasts                    │
│        │  [List of recent items]              │
│        │                                      │
│        │  Quick Actions                       │
│        │  [Action buttons]                    │
│        │                                      │
└────────┴──────────────────────────────────────┘
```

**Features:**
- Left sidebar with navigation icons
- Top header with search bar
- 4 statistics cards
- Recent activity section
- Quick actions section

---

## 🔍 Test 8: Backend API - Test Registration Directly

### What to Do:
Open: **http://localhost:8000/api/v1/docs**

1. Expand **POST /api/v1/auth/register**
2. Click **"Try it out"**
3. Fill in the request body:
```json
{
  "email": "test@example.com",
  "password": "password123",
  "full_name": "Test User",
  "tenant_name": "Test Company"
}
```
4. Click **"Execute"**

### What You Should See:

**Response (Status 201):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user": {
    "id": "8658c0cc-8873-4866-935b-e3c044eb6b4e",
    "email": "test@example.com",
    "full_name": "Test User",
    "role": "admin",
    "tenant_id": "5f084127-2311-43f8-83ed-c45788aa2d03",
    "is_active": true,
    "created_at": "2026-01-07T23:18:00",
    "last_login": "2026-01-07T23:18:00"
  }
}
```

**Key Points:**
- ✅ Status 201 Created
- ✅ JWT token returned
- ✅ User object with all details
- ✅ Role is "admin" (first user in tenant)
- ✅ Tenant was automatically created
- ✅ User ID and Tenant ID are UUIDs

---

## 🔍 Test 9: Backend API - Test Login

### What to Do:
In Swagger UI:

1. Expand **POST /api/v1/auth/login**
2. Click **"Try it out"**
3. Fill in:
```json
{
  "email": "test@example.com",
  "password": "password123"
}
```
4. Click **"Execute"**

### What You Should See:

**Response (Status 200):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user": {
    "id": "8658c0cc-8873-4866-935b-e3c044eb6b4e",
    "email": "test@example.com",
    "full_name": "Test User",
    "role": "admin",
    "tenant_id": "5f084127-2311-43f8-83ed-c45788aa2d03",
    "is_active": true,
    "created_at": "2026-01-07T23:18:00",
    "last_login": "2026-01-07T23:19:35"
  }
}
```

**Notice:**
- `last_login` timestamp updated!

---

## 🔍 Test 10: Backend API - Test /me Endpoint

### What to Do:
1. Copy the `access_token` from login response
2. In Swagger UI, click the **"Authorize"** button (🔒 top right)
3. Paste the token in the format: `Bearer YOUR_TOKEN_HERE`
4. Click **"Authorize"** then **"Close"**
5. Expand **GET /api/v1/auth/me**
6. Click **"Try it out"** then **"Execute"**

### What You Should See:

**Response (Status 200):**
```json
{
  "id": "8658c0cc-8873-4866-935b-e3c044eb6b4e",
  "email": "test@example.com",
  "full_name": "Test User",
  "role": "admin",
  "tenant_id": "5f084127-2311-43f8-83ed-c45788aa2d03",
  "is_active": true,
  "created_at": "2026-01-07T23:18:00",
  "last_login": "2026-01-07T23:19:35"
}
```

---

## 🔍 Test 11: Check Database Tables

### What to Do:
You can verify the data was actually saved to PostgreSQL.

**Expected Database State:**

**tenants table:**
| id | name | slug | is_active |
|----|------|------|-----------|
| 5f084127... | Acme Corp | acme-corp | true |
| (UUID) | Test Company | test-company | true |

**users table:**
| id | email | full_name | role | tenant_id |
|----|-------|-----------|------|-----------|
| 8658c0cc... | john@acme.com | John Doe | admin | 5f084127... |
| (UUID) | test@example.com | Test User | admin | (UUID) |

**All 6 tables exist:**
- ✅ tenants
- ✅ users
- ✅ connectors
- ✅ audit_logs
- ✅ usage_stats
- ✅ forecast_history

---

## 🔍 Test 12: Navigation Links

### What to Do:
On the login/register pages, test the links:

**On Register Page:**
- Click "Sign in" link → Should go to `/lucent/login`

**On Login Page:**
- Click "Create one" link → Should go to `/lucent/register`

### What You Should See:
- Smooth navigation between pages
- No page reload (client-side routing)
- Links are blue and underlined on hover

---

## 🔍 Test 13: Form Validation

### What to Do:

**On Register Page:**
1. Try submitting empty form
2. Try password with < 8 characters
3. Try invalid email format

### What You Should See:
- Browser built-in validation messages
- Email field only accepts valid emails
- Password must be 8+ characters
- All fields are required

---

## 🎯 Expected User Journey

**Complete Flow:**

1. **Visit App** → `http://localhost:3001/lucent/register`
2. **See Register Page** → Clean form on white card
3. **Fill Form** → Name, Company, Email, Password
4. **Click Register** → Button shows "Creating account..."
5. **Success** → Auto-redirect to `/lucent/dashboard`
6. **See Dashboard** → Sidebar, header, stats cards
7. **Token Stored** → In localStorage
8. **Logout (manual)** → Clear localStorage, go to `/lucent/login`
9. **Login Again** → Same credentials
10. **Back to Dashboard** → Authenticated!

---

## ✅ Success Indicators

You'll know Phase 1 is working correctly when:

1. ✅ Register page loads without errors
2. ✅ Can create new account
3. ✅ Automatically redirected after registration
4. ✅ Can login with created credentials
5. ✅ Dashboard shows after login
6. ✅ Backend API docs accessible
7. ✅ All 4 auth endpoints work in Swagger
8. ✅ Token is stored in localStorage
9. ✅ Database has new records
10. ✅ No console errors in browser

---

## 🐛 Common Issues & Solutions

### Issue: "404 Not Found" on auth endpoints
**Solution:** Backend server not running. Start with `uvicorn app.main:app --reload`

### Issue: "CORS error" in browser console
**Solution:** Backend CORS already configured. Check if backend is on port 8000.

### Issue: "Unable to acquire lock" on frontend
**Solution:** Delete `.next/dev/lock` and restart

### Issue: Register button doesn't work
**Solution:** Check browser console for errors. Verify API URL in `.env.local`

### Issue: Not redirected after login
**Solution:** Check browser console. Verify router.push() is working.

---

## 🎉 What Success Looks Like

**When everything works:**

1. Clean, professional UI
2. Smooth form submissions
3. Instant redirects after auth
4. No errors in console
5. Data persisted in database
6. Tokens working correctly
7. All 3 endpoints tested ✅

**You should feel:**
- Confident the auth system works
- Ready to add more features
- Excited about Phase 2!

---

## 📸 Screenshot Checklist

Take screenshots of:
- [ ] Register page
- [ ] Login page
- [ ] Dashboard after login
- [ ] Swagger API docs
- [ ] Successful registration response
- [ ] Successful login response
- [ ] /me endpoint response

---

**Ready to test? Let's go!** 🚀

Start with: **http://localhost:3001/lucent/register**
