# LUCENT Application — User Training Materials Reference

> Comprehensive reference document covering all user-facing features, UI elements, workflows, API endpoints, and configuration options. Extracted from the codebase on 2026-04-04.

---

## Table of Contents

1. [Login & Access](#1-login--access)
2. [Data Upload (Step 1)](#2-data-upload-step-1)
3. [Preprocessing (Step 2)](#3-preprocessing-step-2)
4. [Forecast Configuration (Step 3)](#4-forecast-configuration-step-3)
5. [Run Forecast (Step 4)](#5-run-forecast-step-4)
6. [View Results (Step 5)](#6-view-results-step-5)
7. [Diagnostics (Step 6)](#7-diagnostics-step-6)
8. [Export (Step 7)](#8-export-step-7)
9. [Navigation & Layout](#9-navigation--layout)
10. [Admin Features](#10-admin-features)

---

## 1. Login & Access

### 1.1 Tenant User Login Page

**Route:** `/{tenant}/login`
**File:** `frontend/src/app/[tenant]/login/page.tsx`

**UI Elements:**
- Tenant logo (fetched from branding settings) or fallback BarChart3 icon
- Organization name (displays `tenant.name`)
- Custom welcome message from branding or default: "Sign in to access your organization's dashboard"
- Custom background image from `branding.login_bg_url` (with 50% black overlay)
- **Email field:** Label "Email", Placeholder "you@example.com"
- **Password field:** Label "Password", Placeholder "********"
- **"Sign in" button** (uses tenant's branding primary color)
- **"Don't have an account?"** link to `/{tenant}/register`

**Login Error Messages (exact text):**
- "Your account is pending approval. Please contact your administrator."
- "Your account is not associated with this organization."
- "Organization not found."
- "This organization is currently inactive."
- "Invalid credentials. Please try again."

**Pre-login validation:** Page validates tenant exists via `tenantsPublicApi.getBySlug(tenantSlug)` and fetches branding settings before rendering.

### 1.2 Platform Admin Login Page

**Route:** `/login`
**File:** `frontend/src/app/(auth)/login/page.tsx`

**UI Elements:**
- Red Shield icon
- Title: "Platform Administration"
- **Email field:** Label "Email", Placeholder "admin@lucent.com"
- **Password field:** Label "Password", Placeholder "........"
- **"Sign in as Platform Admin" button** (red-600 background)
- **Footer warning:** "This login is for LUCENT platform administrators only. Tenant users should use their organization's login URL."

**Error message:** "Invalid credentials. This login is for platform administrators only." (red-50 bg, red-200 border, red-700 text)

### 1.3 Registration / Access Request

**Tenant User Access Request:**
**Route:** `/{tenant}/register`
**File:** `frontend/src/app/[tenant]/register/page.tsx`

**UI Elements:**
- Blue BarChart3 icon
- Title: "Request Access"
- Subtitle: "Request access to {tenant.name}"
- **Full Name:** Placeholder "John Doe", required
- **Email:** Placeholder "you@example.com", required
- **Password:** Placeholder "........", required, min 8 characters. Helper: "Must be at least 8 characters"
- **Confirm Password:** Placeholder "........", required
- **Info box (blue):** "Note: Your account will need to be approved by an administrator before you can access the dashboard."
- **"Request Access" button**

**Registration errors:**
- "Passwords do not match."
- "Password must be at least 8 characters long."
- "An account with this email already exists. Please sign in instead."

**Success state:**
- Green CheckCircle icon
- Title: "Request Submitted"
- Message: "Your access request has been sent to the administrators of {tenant.name}."
- Body: "You will receive an email notification once your account has been approved. This usually takes 1-2 business days."
- "Back to Login" button

**Platform Registration Page (`/register`):**
- Title: "Organization Registration"
- Message: "New organizations must be created by a Platform Administrator"
- No direct registration — redirects to Platform Admin contact flow
- "Platform Admin Login" button linking to `/login`

### 1.4 Authentication Flow

**Method:** Custom JWT + bcrypt (Stack Auth variables are configured but NOT actively used — all auth is custom JWT-based)

**JWT Details:**
- Algorithm: HS256
- Default expiration: 24 hours (configurable via `JWT_EXPIRATION_HOURS`)
- Token payload: `{ sub: user.id }` (for users) or `{ sub: admin.id, type: "platform_admin" }` (for platform admins)

**Token storage:**
- Tenant user token: `localStorage.setItem("token", access_token)`
- Platform admin token: `localStorage.setItem("platform_token", access_token)`
- User object: `localStorage.setItem("user", JSON.stringify(user_object))`
- Token passed as `Authorization: Bearer {token}` header on all API calls
- API base URL from `NEXT_PUBLIC_API_URL` env var, fallback: `http://localhost:8000/api/v1`

**Login validation checks (in order):**
1. User exists in database
2. Password matches (bcrypt verify)
3. `is_active == True` (403 "Inactive user" if not)
4. `is_approved == True` (403 "Your account is pending approval..." if not)
5. For tenant-specific login: User's `tenant_id` matches the specified tenant (403 "You do not have access to this organization")

**Logout:** Stateless — `POST /auth/logout` returns success, client deletes token from localStorage. No server-side token revocation.

**Password requirements:** Minimum 8 characters, maximum 100 characters, no special character requirements, bcrypt hashed with automatic salt.

### 1.5 User Approval Workflow

1. User requests access via `/{tenant}/register` (creates user with `is_approved=False`, `role=ANALYST`)
2. User **cannot login** while pending — login returns 403
3. Tenant Admin views pending users in Settings > Users (filter by "Pending Approval")
4. Admin approves (`POST /auth/approve-user/{id}` sets `is_approved=True`) or rejects (`POST /auth/reject-user/{id}` deletes user record)
5. After approval, user can log in normally

**Exception:** First user in organization is auto-created as ADMIN with `is_approved=True`.

### 1.6 Roles & Post-Login Experience

| Role | Description | Default Role | Landing Page | Sidebar Sections |
|------|-------------|-------------|-------------|------------------|
| **Viewer** | Read-only access to dashboards and results | — | `/{tenant}/dashboard` | Main nav only |
| **Analyst** | Full data + forecasting access | Default for new users | `/{tenant}/dashboard` | Main nav only |
| **Admin** | Full access + user/group/settings management | First user in org | `/{tenant}/dashboard` | Main nav + ADMIN section |
| **Platform Admin** | Cross-tenant super-admin | Created separately | `/admin` | Separate red-themed sidebar |

**Viewer** can see: Dashboard, Data, Results, Diagnostics
**Analyst** adds: Connectors, Preprocessing, Forecast
**Admin** adds: Settings > Users, Groups, Connector RLS, Branding

**Dashboard (all roles):**
- Header: "Dashboard" — "Welcome back! Here's an overview of your forecasting projects."
- Stats cards (4): Total Datasets, Active Forecasts, Completed Forecasts, Team Members
- Recent Forecasts section (name, method, status, progress/accuracy)
- Quick Actions: Upload Dataset, New Forecast, View Reports

### 1.7 Onboarding

- No dedicated onboarding wizard, tutorial, or guided tour
- Users land on Dashboard with status cards showing data state
- Empty states on each page guide users with call-to-action buttons (e.g., "Go to Forecast", "Upload Data")

### 1.8 API Endpoints — Authentication

```
POST /auth/register
  Body: { email, password, full_name, tenant_name }
  Response: { access_token, token_type, user }
  Note: Creates new tenant + first admin user

POST /auth/login
  Body: { email, password }
  Response: { access_token, token_type, user }
  Note: Generic login (no tenant validation)

POST /auth/tenant/{tenant_slug}/login
  Body: { email, password }
  Response: { access_token, token_type, user }
  Note: Validates user belongs to tenant

POST /auth/logout
  Response: { message: "Successfully logged out" }

POST /auth/request-access
  Body: { email, password, full_name, tenant_slug }
  Response: { message: "Access request submitted..." }

GET  /auth/me
  Response: UserResponse (current user details)

GET  /auth/pending-users (admin only)
  Response: List[UserResponse] where is_approved=False

POST /auth/approve-user/{user_id} (admin only)
  Response: UserResponse with is_approved=True

POST /auth/reject-user/{user_id} (admin only)
  Response: { message: "User rejected and removed" }
  Note: Deletes user record entirely

POST /platform/login
  Body: { email, password }
  Response: { access_token, token_type, admin }
  Note: Platform admin only
```

---

## 2. Data Upload (Step 1)

### 2.1 Page Location

**Route:** `/{tenant}/data`
**File:** `frontend/src/app/[tenant]/data/page.tsx`

**Main Components:**
- `FileUploader` — Primary file upload (drag-and-drop)
- `ConnectorPanel` — External data source connections
- `SampleDataLoader` — Pre-built sample datasets
- `TemplateDownload` — CSV template generator
- `DatasetList` — List of uploaded datasets
- `StatusCards` — Quick stats dashboard
- `DataPreviewTable` — Paginated data display
- `DataSummary` — Statistical analysis view

### 2.2 Supported File Formats

| Format | Extension | MIME Type |
|--------|-----------|-----------|
| CSV | `.csv` | `text/csv` |
| Excel 2007+ | `.xlsx` | `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` |
| Excel 97-2003 | `.xls` | `application/vnd.ms-excel` |

**CSV Encoding Detection Order:** `utf-8-sig`, `utf-8`, `windows-1256`, `iso-8859-6`, `latin-1`, `cp1252`

### 2.3 Upload UI

**Drag-and-Drop Zone:**
- **Idle text:** "Drag and drop your file here"
- **Drag hover text:** "Drop your file here"
- **File selection button:** "Select File"
- **Icon:** FileSpreadsheet (lucide-react)
- Border changes to primary color on drag

**After file selection:**
- Filename displayed
- File size shown (formatted: "123.4 MB", "45.6 KB", "123 B")
- "Upload File" and "Cancel" buttons appear

**Upload states:**
- Uploading: "Uploading {filename}..." with progress bar
- Success: "Upload successful!"
- Error: Error message with AlertCircle icon (red)

**Helper text below upload area:**
- "Required columns: Date, Entity_ID, Entity_Name, Volume"
- "Accepted formats: CSV (.csv), Excel (.xlsx, .xls)"
- "Supports CSV and Excel files up to {maxSizeMB}MB"

### 2.4 Required Column Format

| Column | Name | Description |
|--------|------|-------------|
| Date | `Date` | Date/timestamp column |
| Entity ID | `Entity_ID` | Unique identifier for entities |
| Entity Name | `Entity_Name` | Human-readable entity name |
| Value | `Volume` | Numeric values to forecast |

### 2.5 Auto-Detection Behavior

If exact column names aren't found, the system auto-detects:

**Date column keywords:** "date", "time", "timestamp", "day", "month", "year", "period"
**Entity column keywords:** "entity_id", "entity", "product", "item", "sku", "category", "store", "location", "region"
**Value column keywords:** "value", "sales", "amount", "quantity", "count", "revenue", "price", "demand", "forecast", "volume"

**Column type detection:**
- `datetime` — Datetime64 types
- `integer` — Integer types
- `float` — Floating-point types
- `boolean` — Boolean types
- `date` — Strings matching YYYY-MM-DD, MM/DD/YYYY, DD-MM-YYYY
- `string` — All others

**What the UI shows after upload:**
- Quick stat cards: Total Rows, Total Columns, Entities, Missing Values %
- Date Range card (start → end)
- Column details table: name, type (badge), unique count, missing count, min/max/mean
- Missing values by column (progress bars)
- Memory usage footer

### 2.6 Cloud Connectors

**Available connector types:**

**Databases:**
| Connector | Fields | Default Port |
|-----------|--------|-------------|
| PostgreSQL | Host, Port, Database, Username, Password | 5432 |
| MySQL | Host, Port, Database, Username, Password | 3306 |
| SQL Server | Host, Port, Database, Username, Password | 1433 |

**Cloud Storage:**
| Connector | Fields |
|-----------|--------|
| AWS S3 | Access Key ID, Secret Access Key, Bucket Name, Region (us-east-1/us-west-2/eu-west-1/ap-southeast-1), Path Prefix |
| Azure Blob | Account Name, Account Key, Container Name, Path Prefix |
| Google Cloud Storage | Project ID, Bucket Name, Service Account JSON, Path Prefix |

**API:**
| Connector | Fields |
|-----------|--------|
| REST API | API URL, Method (GET/POST), Authentication (None/Bearer/Basic/API Key), Auth Token/Key |

**Connector Setup Flow:**
1. Dialog opens: "Connect to External Data Source"
2. Select connector type from grouped cards
3. Fill in configuration fields (required marked with red asterisk)
4. Click "Test Connection" → Shows green "Connection successful!" or red "Connection failed..."
5. Click "Fetch Data" (enabled only after successful test)
6. Toast: "Connector saved! Go to Data Connectors page to set up the data source wizard."

### 2.7 Sample Data

**Available sample datasets:**

| Name | Type | Description | Icon Color |
|------|------|-------------|------------|
| General Forecast | `default` | Basic time series with trend and seasonality | Blue |
| Sales Data | `sales` | Product sales with multiple entities | Green |
| Energy Consumption | `energy` | Hourly energy usage data | Yellow |
| Stock Prices | `stock` | Daily stock price data | Purple |

All samples: 90 days of data (2024-01-01 to 2024-03-31), realistic volume with trend/seasonality/weekly patterns.

**Template types for download:**

| Template | Entities | Rows | Extra Columns |
|----------|----------|------|---------------|
| basic | 2 (PRD-001, PRD-002) | 180 | None |
| extended | 2 | 180 | Marketing_Spend, Temperature, Local_Match, National_Match, International_Match |
| multi_entity | 3 (SKU-001, SKU-002, SKU-003) | 270 | None |
| sales | 2 (WGT-A, WGT-B) | 180 | None |

### 2.8 File Size Limits & Validation

**Default limit:** 100 MB (configurable per tenant)

**Frontend validation errors:**
- "Invalid file type. Supported formats: .csv, .xlsx, .xls"
- "File too large. Maximum size: 100MB"

**Backend validation errors:**
- 400: "Missing required columns: Date, Entity_ID. Required columns are: Date, Entity_ID, Entity_Name, Volume. Found columns: ..."
- 400: "Invalid file type. Supported formats: CSV, XLSX, XLS"
- 400: "The uploaded file is empty"
- 400: "Error parsing file: ..."
- 413: "File too large. Maximum size: {max_size}MB"
- 500: "An error occurred while processing the file"

### 2.9 API Endpoints — Data Upload

```
POST /api/v1/datasets/upload
  Content-Type: multipart/form-data
  Body: file (required)
  Response: { id, name, filename, file_size, file_type, row_count, column_count, columns, message, entities, date_column, entity_column, value_column }

POST /api/v1/datasets/sample
  Body: { sample_type: "default"|"sales"|"energy"|"stock" }
  Response: { id, name, filename, row_count, column_count, entities, message }

GET /api/v1/datasets?skip=0&limit=50&search={optional}
  Response: { datasets: [...], total }

GET /api/v1/datasets/{dataset_id}/preview?page=1&page_size=50
  Response: { columns, data, total_rows, page, page_size, total_pages }

GET /api/v1/datasets/{dataset_id}/summary
  Response: { total_rows, total_columns, missing_values, missing_percentage, date_range, entity_count, columns: [...], missing_by_column, memory_usage_mb }

GET /api/v1/datasets/templates/download?template_type=basic|extended|multi_entity|sales
  Response: CSV file download

PUT /api/v1/datasets/{dataset_id}/columns
  Body: { date_column, entity_column, value_column }
  Response: { id, date_column, entity_column, value_column, entities, date_range }
```

### 2.10 Data Storage

- DataFrame stored in Redis: key `dataset:{dataset_id}`, format JSON (pandas orient="split")
- Metadata in Redis: key `dataset_meta:{dataset_id}`
- TTL: 4 hours (session-based)
- Permanent metadata in PostgreSQL `datasets` table

---

## 3. Preprocessing (Step 2)

### 3.1 Page Location

**Route:** `/{tenant}/preprocessing`
**File:** `frontend/src/app/[tenant]/preprocessing/page.tsx`

### 3.2 Page Layout

**Header:**
- Title: "Data Preprocessing"
- Subtitle: "Clean and transform your data before forecasting"
- Action buttons (top right): Reset (RotateCcw icon), Download (Download icon), Continue to Forecasting (ArrowRight icon)

**Dataset & Entity Selection Card (two columns):**
- Left: Dataset dropdown with row count badges, info line: "{rows} rows, {columns} columns . {entities} entities"
- Right: Entity / SKU dropdown with previous/next navigation (ChevronLeft/ChevronRight), "All Entities" or individual names, position: "{index} of {total}"

**Time Series Chart:**
- Title: "Time Series Preview" (or "Time Series -- {Entity Name}")
- Plotly scatter plot with lines and markers
- X-axis: Date, Y-axis: Volume
- Height: 400px

**5 Preprocessing Tabs:**

| Tab | Icon | Purpose |
|-----|------|---------|
| Missing Values | AlertTriangle | Handle missing data |
| Duplicates | Copy | Find and remove duplicates |
| Outliers | TrendingUp | Detect and handle outliers |
| Replace Values | Replace | Custom value replacement |
| Aggregation | Calendar | Time frequency aggregation |

### 3.3 Missing Values Handler

**Component:** `MissingValuesHandler.tsx`

**Available Methods:**

| Method | Description |
|--------|-------------|
| Drop Rows | Remove rows with missing values |
| Fill with Zero | Replace missing values with 0 |
| Fill with Mean | Replace with column mean |
| Fill with Median | Replace with column median |
| Fill with Mode | Replace with most frequent value |
| Forward Fill | Use previous valid value |
| Backward Fill | Use next valid value |
| Linear Interpolation | Linear interpolation between values |
| Spline Interpolation | Spline-based interpolation |

**Default method:** Forward Fill

**UI Controls:**
- Summary stats (3 cards): Total Rows, Missing Values, Affected Columns
- Method dropdown with descriptions
- Column selection: "Select All" / "Select None" buttons, scrollable checkbox list showing column name, data type badge, missing percentage progress bar
- Apply button: "Apply to {N} Column(s)"

**Success toast:** "Missing values handled successfully"
**Empty state:** Green checkmark + "No missing values found in the dataset"

### 3.4 Outlier Detection & Handling

**Component:** `OutlierHandler.tsx`

**Detection Methods:**

| Method | Default Threshold | Description |
|--------|-------------------|-------------|
| IQR | 1.5 | Interquartile Range (Q1 - 1.5xIQR to Q3 + 1.5xIQR) |
| Z-Score | 3 | Standard deviations from mean |
| Percentile | 95 | Values outside percentile bounds (1st to 95th) |

**Action Options:**

| Action | Description |
|--------|-------------|
| Remove Rows | Delete rows containing outliers |
| Cap Values | Replace outliers with boundary values |
| Replace with Mean | Replace outliers with column mean |
| Replace with Median | Replace outliers with column median |
| Flag Only | Add column marking outliers (no data change) |

**Default action:** Cap Values

**UI Controls:**
- Detection settings: Method dropdown + Threshold number input (step=0.1)
- "Detect Outliers" button (outline variant)
- Summary (3 cards): Total Rows, Total Outliers, Affected Columns
- Column list: checkbox + column name + outlier count badge + bounds display
- "Apply to {N} Column(s)" button

**Success toast:** "Outliers handled successfully"
**Empty state:** Green checkmark + "No outliers detected with current settings"

### 3.5 Duplicate Handling

**Component:** `DuplicateHandler.tsx`

**Methods:**

| Method | Description |
|--------|-------------|
| Keep First | Keep the first occurrence |
| Keep Last | Keep the last occurrence |
| Drop All | Remove all duplicate rows |

**Default method:** Keep First

**UI Controls:**
- Column selection for duplicate detection (optional, defaults to all columns)
- "Analyze Duplicates" button
- Summary (2 cards): Total Rows, Duplicate Rows (with percentage)
- Impact preview showing expected row count after applying
- "Remove Duplicates" button

**Success toast:** "Duplicates handled successfully"
**Empty state:** Green checkmark + "No duplicates found in the dataset"

### 3.6 Value Replacement

**Component:** `ValueReplacer.tsx`

**Match Types:** Exact Match, Contains, Regex
**Default:** Exact Match

**UI Controls:**
- Add Rule Form: Column selector, Match Type selector, Find Value input, Replace With input
- "Add Replacement Rule" button (Plus icon)
- Rules list: Shows each rule as `"oldValue" -> "newValue"` with match type badge and remove button
- "Apply {N} Replacement Rule(s)" button
- Rules applied sequentially with progress

**Success toast:** "Value replacement complete. {affected} values affected."

### 3.7 Time Aggregation

**Component:** `TimeAggregator.tsx`

**Frequency Options:**

| Label | Code | Description |
|-------|------|-------------|
| Daily | D | Aggregate to daily |
| Weekly | W | Aggregate to weekly |
| Monthly | M | Aggregate to monthly |
| Quarterly | Q | Aggregate to quarterly |
| Yearly | Y | Aggregate to yearly |

**Default frequency:** Monthly (M)

**Aggregation Methods:**

| Method | Description |
|--------|-------------|
| Sum | Total values |
| Mean | Average values |
| Median | Median value |
| Minimum | Smallest value |
| Maximum | Largest value |
| First Value | First value in period |
| Last Value | Last value in period |

**Default method:** Sum

**UI Controls:**
- Target Frequency dropdown + Default Method dropdown
- Date Column dropdown
- Column-specific methods (optional): Per-column method override via checkboxes
- Info box: "Groups data by the selected time frequency / Aggregates numeric columns / Preserves entity groupings"
- "Aggregate to {Frequency Label}" button

**Success toast:** "Time aggregation applied successfully"

### 3.8 Reset & Download

- **Reset button:** Deletes preprocessed data from Redis, reverts to original. Toast: "Preprocessing reset to original data"
- **Download button:** Streams CSV of current state (preprocessed or original)
- **No individual undo** — only full reset available

### 3.9 API Endpoints — Preprocessing

```
GET  /preprocessing/{dataset_id}/entities          — List entities
GET  /preprocessing/{dataset_id}/entity/{id}/stats  — Entity statistics
GET  /preprocessing/{dataset_id}/entity/{id}/data   — Entity data (paginated)

GET  /preprocessing/{dataset_id}/missing            — Analyze missing values
POST /preprocessing/{dataset_id}/missing            — Handle missing values

GET  /preprocessing/{dataset_id}/duplicates         — Analyze duplicates
POST /preprocessing/{dataset_id}/duplicates         — Remove duplicates

GET  /preprocessing/{dataset_id}/outliers           — Detect outliers
POST /preprocessing/{dataset_id}/outliers           — Handle outliers

POST /preprocessing/{dataset_id}/aggregate          — Time aggregation
POST /preprocessing/{dataset_id}/replace            — Value replacement

POST /preprocessing/{dataset_id}/reset              — Reset to original
GET  /preprocessing/{dataset_id}/download           — Download as CSV

GET  /preprocessing/{dataset_id}/regressors         — Detect regressor columns
```

**Redis caching:** Preprocessed data stored at `preprocessed:{dataset_id}` or `preprocessed:{dataset_id}:{entity_id}` with 2-hour TTL.

---

## 4. Forecast Configuration (Step 3)

### 4.1 Page Location

**Route:** `/{tenant}/forecast`
**File:** `frontend/src/app/[tenant]/forecast/page.tsx`

### 4.2 Page Layout

**Header:**
- Title: "Forecast"
- Subtitle: "Configure and run time series forecasts using ARIMA, ETS, or Prophet models"
- Buttons (top right): Reset, Run Forecast / Forecast All

**3-column grid:**
- Left panel (4/12 width): Configuration controls
- Right panel (8/12 width): Tabbed results (Configure / Progress / Results)

### 4.3 Method Selection

**Component:** `MethodSelector.tsx`
**UI type:** Clickable cards (not radio/dropdown)

| Method | Icon | Description | Tags |
|--------|------|-------------|------|
| ARIMA | TrendingUp | Best for data with trends and autocorrelation. Handles non-stationary series. | Trend, Auto-correlation |
| ETS | Waves | Best for data with clear level, trend, and seasonal patterns. | Seasonality, Smoothing |
| Prophet | Calendar | Best for business data with holidays, missing data, and strong seasonality. | Business, Holidays, Flexible |

Selected card: Blue border + primary background (`bg-primary/5`)
**Default:** ARIMA

### 4.4 Dataset & Entity Selectors

**Dataset Selector** (`DatasetSelector.tsx`):
- Label: "Dataset" (Database icon)
- Description: "Select a dataset to forecast"
- Dropdown shows: dataset name + "{row_count} rows . {entity_count} entities"
- Selected info: Rows, Columns, Date Range

**Entity Selector** (`EntitySelector.tsx`):
- Label: "Entity" (Users icon)
- Description: "Select an entity or forecast all"
- Special option "All Entities" (if 2+ entities): enables batch forecast mode
- Shows: "{count} entities . {total_obs} total observations"
- Individual items: "{entity_name} / {row_count} observations . {missing_count} missing"

### 4.5 Basic Forecast Settings

**Component:** `ForecastSettings.tsx`

| Field | Type | Range | Default | Help Text |
|-------|------|-------|---------|-----------|
| Forecast Horizon | Number input | 1-365 | 30 | "Number of periods to forecast (1-365)" |
| Data Frequency | Dropdown | Daily, Weekly, Monthly | Daily | Maps to D, W, M |
| Confidence Level | Slider | 80%-99% (step 1%) | 95% | "Width of prediction intervals" |

### 4.6 ARIMA Settings

**Component:** `ARIMASettings.tsx`

**Auto-detect toggle:**
- Label: "Auto-detect Parameters"
- Help: "Find optimal p, d, q values automatically"
- Default: ON

**Manual parameters (when auto OFF):**

| Parameter | Label | Range | Default |
|-----------|-------|-------|---------|
| p | p (AR order) | 0-5 | 1 |
| d | d (Differencing) | 0-2 | 1 |
| q | q (MA order) | 0-5 | 1 |

**Seasonal parameters (optional):**

| Parameter | Label | Range |
|-----------|-------|-------|
| P | P | 0-3 |
| D | D | 0-2 |
| Q | Q | 0-3 |
| s | s | >= 1 |

Help: "P, D, Q: Seasonal orders. s: Season period (e.g., 7 for weekly, 12 for yearly)"

### 4.7 ETS Settings

**Component:** `ETSSettings.tsx`

**Auto-detect toggle:**
- Label: "Auto-detect Parameters"
- Help: "Find optimal ETS configuration automatically"
- Default: ON

**Manual parameters (when auto OFF):**

| Parameter | Label | Options |
|-----------|-------|---------|
| error | Error Type | Additive, Multiplicative |
| trend | Trend | None, Additive, Multiplicative |
| seasonal | Seasonality | None, Additive, Multiplicative |
| seasonal_periods | Seasonal Period | Number (shown when seasonal != "none") |
| damped_trend | Damped Trend | Toggle (shown when trend != "none"), help: "Trend fades over time" |

### 4.8 Prophet Settings

**Component:** `ProphetSettings.tsx`
(No auto/manual toggle — all settings always visible)

| Parameter | Label | Type | Range | Default |
|-----------|-------|------|-------|---------|
| changepoint_prior_scale | Trend Flexibility | Slider | 0.01-0.5 | 0.05 |
| seasonality_mode | Seasonality Mode | Dropdown | Additive, Multiplicative | Additive |
| yearly_seasonality | Yearly Seasonality | Toggle | — | ON |
| weekly_seasonality | Weekly Seasonality | Toggle | — | ON |
| daily_seasonality | Daily Seasonality | Toggle | — | OFF |

Help for slider: "Higher values allow more trend changes"
Help for mode: "Multiplicative for seasonality that scales with the level"

### 4.9 Regressor Selection

**Component:** `RegressorSelector.tsx`
- Only shown if dataset has extra numeric columns beyond date/value/entity
- Only used with Prophet method
- Green-bordered card with heading: "External Regressors (Prophet)"
- Text: "Your data contains extra columns that can improve Prophet forecast accuracy. Select which to use:"
- Each column shows: name, type badge ("binary"/"numeric"), sample values
- Tip: "Select columns that influence your volume (e.g., marketing spend, weather, events). Regressors are only used with Prophet."

### 4.10 Cross-Validation Settings

**Component:** `CrossValidationSettings.tsx`

**Enable toggle:**
- Label: "Enable Cross Validation"
- Help: "Assess model performance before final forecast"
- Default: OFF

| Parameter | Label | Type | Range | Default |
|-----------|-------|------|-------|---------|
| folds | Number of Folds | Number | 2-10 | 5 |
| method | Validation Method | Dropdown | Rolling, Expanding | Rolling |
| initialTrainSize | Initial Train Size (%) | Number | 50-90% | 70% |

Help text:
- Rolling: "Fixed-size training window slides forward"
- Expanding: "Training window grows with each fold"

### 4.11 Auto-Detect Parameters Button

- Label: "Auto-detect Parameters"
- Icon: Wand2
- Loading: "Detecting..." with Loader2 spinner
- Only shown for ARIMA and ETS
- Calls `POST /forecast/auto-params/{method}?dataset_id={id}&entity_id={id}`
- Success toast: "Parameters auto-detected — Optimal parameters found for [METHOD]"

---

## 5. Run Forecast (Step 4)

### 5.1 Run Button

| Mode | Button Label | Icon |
|------|-------------|------|
| Single entity | "Run Forecast" | Play |
| All entities | "Forecast All" | Play |
| Running | "Running..." | Loader2 (spinning) |

Disabled when: no dataset selected, no entity selected, or already running.

### 5.2 Single Entity Execution

1. POST `/forecast/run` with all settings (120s timeout)
2. Tab switches to "Progress" immediately
3. `ForecastProgress` component polls `/forecast/status/{id}` every 2 seconds
4. On completion, auto-switches to "Results" tab

**Progress Steps Display:**

| Step | Label | Triggers at |
|------|-------|-------------|
| 1 | Loading data | >= 30% |
| 2 | Fitting model | >= 70% |
| 3 | Generating predictions | >= 90% |
| 4 | Calculating metrics | >= 100% |

**Status Badges:**
- Pending: Clock icon, gray
- Running: Spinner, blue
- Completed: Checkmark, green
- Failed: X icon, red

**Completed message:** "Forecast completed successfully! View the results in the Results tab." (green)
**Failed message:** Error detail in red box

### 5.3 Batch Forecast Execution

1. POST `/forecast/batch` with entity_ids list (120s timeout)
2. Returns immediately with batch_id
3. Polls `/forecast/batch/{batch_id}` every 3 seconds
4. Shows: progress bar + "{completed}/{total} processed" + completed/failed/remaining counts
5. When status != "running", switches to results tab

### 5.4 API Endpoints — Forecast

```
POST /forecast/run
  Body: { dataset_id, entity_id, method, horizon, frequency, confidence_level, arima_settings, ets_settings, prophet_settings, cross_validation, regressor_columns }
  Response: ForecastResultResponse

GET /forecast/status/{forecast_id}
  Response: ForecastResultResponse (poll every 2s)

POST /forecast/batch
  Body: { dataset_id, entity_ids (1-50), method, horizon, frequency, confidence_level, ...settings, regressor_columns }
  Response: BatchForecastStatusResponse { batch_id, total, completed, failed, in_progress, status, results }

GET /forecast/batch/{batch_id}
  Response: BatchForecastStatusResponse (poll every 3s)

POST /forecast/auto-params/{method}?dataset_id={id}&entity_id={id}
  Response: { method, recommended_params, data_characteristics }

GET /forecast/methods
  Response: [ { id, name, description, supports_seasonality, supports_exogenous, default_settings } ]
```

### 5.5 Validation Errors

| Rule | Error |
|------|-------|
| Horizon exceeds tenant max | "Forecast horizon ({value}) exceeds maximum allowed ({max} days)" |
| Batch size exceeds tenant max | "Batch size ({count}) exceeds maximum allowed ({max} entities)" |
| Minimum data points | At least 10 required |

---

## 6. View Results (Step 5)

### 6.1 Page Location

**Route:** `/{tenant}/results`
**File:** `frontend/src/app/[tenant]/results/page.tsx`
**URL parameter:** `?forecastId={id}` (also reads from Zustand store)

### 6.2 Page Header

- Title: "Results"
- Subtitle: "View forecast predictions, metrics, and export results"
- Forecast ID displayed in monospace
- Status badge (Completed/Running/Pending/Failed)
- Method badge (uppercase: ARIMA, ETS, PROPHET)
- Entity ID badge

### 6.3 Results Tabs

**4 tabs:**

| Tab | Icon | Content |
|-----|------|---------|
| Overview | BarChart3 | Forecast chart (Plotly) |
| Data | Table2 | Paginated prediction table |
| Model | Info | Model parameters and coefficients |
| Export | FileDown | CSV/JSON download buttons |

### 6.4 Forecast Chart

**Component:** `ForecastChart.tsx`
**Library:** Plotly (react-plotly.js)

**Chart traces:**

| Trace | Color | Style | Hover |
|-------|-------|-------|-------|
| Confidence Interval Band | rgba(59,130,246,0.12) | Filled polygon | — |
| Forecast Line | #3b82f6 (blue) | Solid, 2.5px | `Value: {y:.4f}` |
| Upper Bound | #93c5fd (light blue) | Dashed, 1px | `Upper: {y:.4f}` |
| Lower Bound | #93c5fd (light blue) | Dashed, 1px | `Lower: {y:.4f}` |

**Chart properties:**
- Height: 420px
- Hover mode: "x unified"
- X-axis: "Date" (tick angle: -40 degrees)
- Y-axis: "Value"
- Grid lines: rgba(0,0,0,0.05)
- Legend: Horizontal, below chart
- Toolbar: Standard Plotly (zoom, pan, download, reset) — removed: select2d, lasso2d, autoScale2d

### 6.5 Metrics Dashboard

**Component:** `MetricsCards.tsx`
**Layout:** 2 columns mobile, 4 columns desktop

| Metric | Label | Icon | Format | Color Thresholds |
|--------|-------|------|--------|-----------------|
| MAE | Mean Absolute Error | Target | Number (4 decimals) | Neutral (grey) |
| RMSE | Root Mean Square Error | TrendingUp | Number (4 decimals) | Neutral (grey) |
| MAPE | Mean Absolute Percentage Error | Percent | Percentage | <= 5%: Green, <= 15%: Yellow, > 15%: Red |
| R2 | Coefficient of Determination | BarChart3 | Decimal | >= 0.9: Green, >= 0.7: Yellow, < 0.7: Red |

### 6.6 Prediction Data Table

**Component:** `ResultsTable.tsx`

**Columns:**
- # (row number, centered)
- Date (as-is from API)
- Predicted Value (monospace, 4 decimal places, right-aligned)
- Lower Bound (monospace, muted text, 4 decimal places, right-aligned)
- Upper Bound (monospace, muted text, 4 decimal places, right-aligned)

**Pagination:**
- Page size: 50 rows
- Controls: First, Previous, Next, Last (chevron icons)
- Display: "Showing X-Y of Z rows" + "Page X of Y"
- Non-finite values shown as "-"

**Card header:** "Prediction Data — {total} predictions with confidence intervals"

### 6.7 Entity Switching (Batch Results)

**Component:** `BatchForecastResults.tsx`

- Entity selector dropdown at top
- Status display: completed count (green CheckCircle2), failed count (red XCircle)
- Selected entity shows: chart + metrics + model params
- "Download All" button generates CSV with columns: Entity, Date, Forecast, Lower Bound, Upper Bound
- Filename: `batch_forecast_{batchId}.csv` (UTF-8 BOM for Excel compatibility)
- Failed entities listed with error messages

### 6.8 Navigation Buttons (below results)

| Button | Icon | Action |
|--------|------|--------|
| View Results | LineChart | Navigate to `/{tenant}/results?forecastId={id}` |
| View Diagnostics | Stethoscope | Navigate to `/{tenant}/diagnostics?forecastId={id}` |

---

## 7. Diagnostics (Step 6)

### 7.1 Page Location

**Route:** `/{tenant}/diagnostics`
**File:** `frontend/src/app/[tenant]/diagnostics/page.tsx`
**URL parameter:** `?forecastId={id}`

### 7.2 Page Header

- Title: "Diagnostics"
- Subtitle: "Analyze forecast quality with residual diagnostics, seasonality, and model comparison"
- Forecast ID (monospace)
- Diagnostics badge + Method badge

### 7.3 Quality Gauges (Always Visible)

**Component:** `QualityGauge.tsx` — Circular SVG progress indicators

**4 gauges in grid (2 col mobile, 4 col desktop):**

| Gauge | Description | Derived From | Formula |
|-------|-------------|-------------|---------|
| Accuracy | Prediction precision | MAPE | 100 - MAPE |
| Stability | Forecast consistency | CV of residuals | 100 / (1 + CV) |
| Reliability | Statistical confidence | Ljung-Box p-value | p_value * 100 |
| Coverage | Interval coverage | % actuals within intervals | coverage_percent |

**Color coding:**
- >= 80: Green (#22c55e) — "Excellent"
- 60-79: Yellow (#eab308) — "Good"
- 50-59: Yellow — "Fair"
- < 50: Red (#ef4444) — "Poor"

**Overall score:** Average of 4 gauge values

### 7.4 Diagnostics Tabs

| Tab | Icon | Content |
|-----|------|---------|
| Residuals | BarChart3 | Residual chart + ACF chart |
| Seasonality | Waves | Strength bars + seasonal component chart |
| Model | Settings2 | Parameters + coefficients table |
| Quality | Gauge | Detailed quality cards |

### 7.5 Residual Analysis

**Component:** `ResidualChart.tsx`

**Chart:** Plotly scatter plot
- Residuals as blue dots (size 5, opacity 0.7, color #3b82f6)
- Red dashed zero reference line (#ef4444, 1.5px)
- X-axis: Observation Index, Y-axis: Residual Value
- Height: 420px

**Statistical test badges below chart:**
- White Noise: Green if true, Red if false
- Ljung-Box: "{statistic} (p={p_value})"
- Jarque-Bera: "{statistic} (p={p_value})"

### 7.6 ACF/PACF Charts

**Component:** `ACFChart.tsx`

**ACF chart:** Bar chart of autocorrelation values (up to 20 lags)
- Bars within confidence: Blue (#3b82f6)
- Bars exceeding confidence: Red (#ef4444)
- Confidence bands: Dashed gray lines (#94a3b8)
- X-axis: Lag (0-20), Y-axis: Correlation (-1.0 to 1.0)
- Height: 300px

**PACF chart (if available):** Same layout, purple (#8b5cf6)

**Description:** "Bars exceeding the dashed confidence bands indicate statistically significant correlations."

### 7.7 Seasonality Panel

**Component:** `SeasonalityPanel.tsx`

**Strength bars (2 columns):**
- Seasonal Strength: 0-100%, colored Red (<30%), Yellow (30-70%), Green (>=70%)
- Trend Strength: Same scale and colors

**Period detection badges:**
- "Detected Period: {period} observations" (outline)
- "No period detected" (secondary)
- "Strong Seasonality" badge if >= 0.7
- "Weak Seasonality" badge if < 0.3

**Seasonal component chart (if available):** Purple line (#8b5cf6), height 280px

### 7.8 Model Parameters Panel

**Component:** `ModelParametersPanel.tsx`

**Method descriptions:**
- ARIMA: "ARIMA -- AutoRegressive Integrated Moving Average"
- ETS: "ETS -- Error, Trend, Seasonality (Exponential Smoothing)"
- Prophet: "Prophet -- Additive Regression Model by Meta"

**Display:**
- Method badge (uppercase)
- AIC badge: "AIC: {value}" + BIC badge: "BIC: {value}"
- Parameters grid (2 columns): Key-value pairs in rounded muted boxes
- Coefficients table: columns Coefficient | Value | Std. Error (4 decimal places)

### 7.9 Model Comparison

**Component:** `ModelComparisonTable.tsx`

- Request: POST `/diagnostics/compare` with list of forecast IDs (2-5)
- Composite score: 0.4 x accuracy + 0.3 x reliability + 0.2 x stability + 0.1 x coverage

**Table columns:** Forecast ID, Method (badge), Entity, MAE, RMSE, MAPE (%), R2, Accuracy, Stability

**Best model:** Trophy icon (yellow) + "Best" badge + green row highlight (bg-green-50)

### 7.10 API Endpoints — Diagnostics

```
GET /diagnostics/{forecast_id}
  Response: { forecast_id, entity_id, method, residual_analysis, model_parameters, seasonality, quality_indicators }

POST /diagnostics/compare
  Body: { forecast_ids: string[] (2-5) }
  Response: Comparison results with composite scores
```

---

## 8. Export (Step 7)

### 8.1 Export Panel Location

**Component:** `ExportPanel.tsx`
**Location:** Export tab in Results page (`/{tenant}/results`, 4th tab)

### 8.2 CSV Download

**Card title:** "CSV Download"
**Description:** "Download raw prediction data (date, value, lower bound, upper bound) as a CSV file."
**Button:** "Download CSV" (Download icon)
**Loading state:** "Downloading..." with spinner

**CSV columns:** date, value, lower_bound, upper_bound
**Filename:** `forecast-{forecastId}.csv`

### 8.3 JSON Report Export

**Card title:** "JSON Report"
**Description:** "Export a full JSON report including predictions, metrics, model summary, and metadata."
**Button:** "Export Report (JSON)" (FileJson icon)
**Loading state:** "Exporting..." with spinner

**JSON report structure:**
```json
{
  "export_metadata": { "exported_at", "forecast_id", "tenant_id", "user_id" },
  "forecast_info": { "id", "dataset_id", "entity_id", "method", "status", "created_at", "completed_at" },
  "predictions": [ { "date", "value", "lower_bound", "upper_bound" } ],
  "metrics": { "mae", "rmse", "mape", "mse", "r2", "aic", "bic" },
  "model_summary": { "method", "parameters", "coefficients", "diagnostics", "regressors_used" },
  "cv_results": { "folds", "method", "metrics_per_fold", "average_metrics" },
  "summary": { "total_predictions", "has_confidence_intervals", "has_metrics", "has_cv_results" }
}
```

**Filename:** `forecast-report-{forecastId}.json`

### 8.4 Batch Export

- Button: "Download All" (in batch results view)
- CSV columns: Entity, Date, Forecast, Lower Bound, Upper Bound
- Filename: `batch_forecast_{batchId}.csv`
- UTF-8 BOM prefix for Excel compatibility

### 8.5 Forecast Metadata Card

**Title:** "Forecast Metadata"
**Fields (2-column grid):**
- Forecast ID (monospace)
- Entity
- Method (uppercase badge)
- Status (green check + "Completed")
- Created (formatted date-time)
- Completed (formatted date-time)

### 8.6 API Endpoints — Export

```
GET /results/download/{forecast_id}
  Response: StreamingResponse (CSV)
  Headers: Content-Type: text/csv; charset=utf-8
           Content-Disposition: attachment; filename="{filename}"
  Error: 400 if not completed or no predictions

POST /results/export/{forecast_id}
  Response: JSON report object
  Error: 400 if not completed
```

---

## 9. Navigation & Layout

### 9.1 Root Layout

**File:** `frontend/src/app/layout.tsx`
- Global AuthProvider wrapper
- Fonts: Geist Sans + Geist Mono
- Page title: "LUCENT - Forecasting Platform"

### 9.2 Tenant Layout

**File:** `frontend/src/app/[tenant]/layout.tsx`
- Two-column layout: Sidebar (left, 256px) + Main content (right)
- Main content: Header (64px) + Scrollable page content
- Auth check: Redirects unauthenticated to `/{tenant}/login`
- Tenant validation: Confirms user belongs to tenant

### 9.3 Sidebar

**Component:** `frontend/src/components/layout/Sidebar.tsx`
**Width:** 256px (w-64), full height, border-right

**Logo section:** "LUCENT" with BarChart3 icon (primary blue)

**Main Navigation (all users):**

| # | Label | Icon | Path |
|---|-------|------|------|
| 1 | Dashboard | Home | `/dashboard` |
| 2 | Data | Database | `/data` |
| 3 | Connectors | Plug | `/connectors` |
| 4 | Preprocessing | FileText | `/preprocessing` |
| 5 | Forecast | TrendingUp | `/forecast` |
| 6 | Results | LineChart | `/results` |
| 7 | Diagnostics | Activity | `/diagnostics` |
| 8 | Settings | Settings | `/settings` |

**Admin-only section** (visible when `user.role === 'admin'`):
- Divider + "ADMIN" label (uppercase, gray)

| # | Label | Icon | Path |
|---|-------|------|------|
| 1 | Users | Users | `/settings/users` |
| 2 | Groups | UsersRound | `/settings/groups` |
| 3 | Connector RLS | Link2 | `/settings/connectors` |
| 4 | Branding | Palette | `/settings/branding` |

**Active state:** Primary blue background + white text
**Inactive state:** Gray text + hover light gray

**Footer:** User avatar (initials circle), name (truncated), role (capitalized)

### 9.4 Header / Top Bar

**Component:** `frontend/src/components/layout/Header.tsx`
**Height:** 64px, border-bottom

**Left section:**
- Tenant logo (from branding, falls back to Building2 icon) + tenant name (clickable -> `/dashboard`)
- Vertical divider
- Search bar: placeholder "Search datasets, forecasts..."

**Right section:**
- Notifications bell icon with red badge count (e.g., "3")
  - Sample notifications: "Forecast completed", "Data uploaded", "Team member added"
- User menu dropdown: Avatar + name + role
  - Items: Profile, Settings, Billing, --- , **Log out** (red, LogOut icon)

### 9.5 Complete Route Map

**Public routes:**
- `/{tenant}/login`
- `/{tenant}/register`
- `/login`, `/register`

**Protected routes (require auth):**
- `/{tenant}/dashboard`
- `/{tenant}/data`
- `/{tenant}/connectors`
- `/{tenant}/preprocessing`
- `/{tenant}/forecast`
- `/{tenant}/results`
- `/{tenant}/diagnostics`
- `/{tenant}/settings`

**Admin-only routes:**
- `/{tenant}/settings/users`
- `/{tenant}/settings/groups`
- `/{tenant}/settings/connectors`
- `/{tenant}/settings/branding`

**Platform admin routes:**
- `/admin` — Platform dashboard
- `/admin/users` — All users across tenants
- `/admin/tenants` — Manage all tenants
- `/admin/tenants/[id]` — Tenant details

---

## 10. Admin Features

### 10.1 User Management

**Route:** `/{tenant}/settings/users`
**File:** `frontend/src/app/[tenant]/settings/users/page.tsx`

**Page header:**
- Title: "User Management"
- Subtitle: "Manage users in {organization}"
- "Add User" button (top right)

**Stats cards (4 columns):** Total Users, Active Users, Pending Approval, User Groups

**Filters:** Search (name/email), Status (All/Active/Inactive), Approval (All/Approved/Pending), Role (All/Admin/Analyst/Viewer)

**Users table columns:** Name, Email, Role, Groups (badges, "+X more"), Status (Active/Inactive), Approved (checkmark/Pending), Actions

**Row actions (3-dot menu):** Edit, Reset Password, Approve (if pending), Deactivate/Activate, Delete (red)

**Dialogs:**

| Dialog | Fields |
|--------|--------|
| Add New User | Full Name, Email, Password ("Minimum 8 characters"), Role (Admin/Analyst/Viewer, default: Analyst) |
| Edit User | Email (disabled), Full Name, Role |
| Delete User | Confirmation: "Are you sure you want to delete '{email}'? This action cannot be undone." |
| Reset Password | Generate Random / Set Custom toggle, shows generated password with Copy button on success |

### 10.2 User Groups & RLS

**Route:** `/{tenant}/settings/groups`
**File:** `frontend/src/app/[tenant]/settings/groups/page.tsx`

**Page header:**
- Title: "User Groups"
- Subtitle: "Manage user groups and RLS values for {organization}"
- "Create Group" button

**Groups table columns:** Name, Description, Members (count), RLS Values (purple badges, "+X more"), Status (Active/Inactive), Actions

**Row actions:** View Details, Edit, Manage Members, Delete

**Dialogs:**

| Dialog | Content |
|--------|---------|
| Create Group | Group Name, Description (optional), Assign Entities (RLS): Data Source dropdown + entity checkbox list with "Select All"/"Deselect All" |
| Edit Group | Same as Create, existing RLS as purple Shield badges |
| Group Detail | Read-only: name, description, RLS values (purple badges), members list |
| Manage Members | 2-column: Current Members (with Remove/UserMinus) + Available Users (with Add/UserPlus) |
| Delete Group | "Are you sure? This will remove all member associations." |

**No data sources state:** "No data sources configured yet. Run the Setup Wizard on a connector first."

### 10.3 Data Source RLS Configuration

**Route:** `/{tenant}/settings/connectors`
**File:** `frontend/src/app/[tenant]/settings/connectors/page.tsx`

**Page header:**
- Title: "Data Source RLS"
- Subtitle: "Assign entities from your data sources to user groups for {organization}"

**Info card (blue):** "How RLS Works" with Shield icon explaining 3 steps:
1. Select a data source below
2. Choose a user group
3. Pick which entities that group can access

**Per data source card:**
- Name (Table2 icon) + connector info + type badge + table name (monospace)
- Entity count (purple badge) + RLS column (blue Shield badge)
- RLS toggle switch: "RLS On" (green) / "RLS Off" (gray)
- Groups assignment table: Group | Assigned Entities (green badges) | "Assign" button

**Entity Assignment Dialog:**
- Title: "Assign Entities to {group}"
- Select All / Deselect All + counter
- Scrollable checkbox list of entities (monospace)
- "Save (X entities)" button

### 10.4 Branding Settings

**Route:** `/{tenant}/settings/branding`
**File:** `frontend/src/app/[tenant]/settings/branding/page.tsx`

**Page header:**
- Title: "Branding Settings"
- Subtitle: "Customize your organization's appearance"

**Logo & Images Card (Image icon):**

| Field | Placeholder | Helper |
|-------|-------------|--------|
| Logo URL | https://example.com/logo.png | Recommended size: 200x50px (PNG or SVG) |
| Favicon URL | https://example.com/favicon.ico | Recommended size: 32x32px (ICO or PNG) |
| Login Background Image URL | https://example.com/background.jpg | Recommended size: 1920x1080px (JPG or PNG) |

Logo preview shown when URL provided.

**Brand Colors Card (Palette icon):**

| Field | Default | Helper |
|-------|---------|--------|
| Primary Color | #2563eb | Main brand color (buttons, links) |
| Secondary Color | #1e40af | Secondary accent color |
| Accent Color | #3b82f6 | Highlight and hover states |

Color picker + hex input for each. Preview squares shown below.

**Login Page Message Card (MessageSquare icon):**
- Textarea (3 rows, max 500 chars)
- Placeholder: "Welcome to our platform! Please sign in to access your dashboard."
- Character counter: "X/500 characters"

**Buttons:** "Reset to Defaults" (RotateCcw icon) + "Save Changes" (Save icon)

### 10.5 Platform Admin

**Route:** `/admin`
**File:** `frontend/src/app/(admin)/admin/page.tsx`

**Separate sidebar (red theme):**
- Logo: Red Shield icon + "Platform Admin"
- Nav: Dashboard (Home), Tenants (Building2), All Users (Users)
- Logout button + admin info footer

**Stats cards (4 columns):** Total Tenants, Total Users, Active Users, Pending Approvals

**Quick actions:**
- Tenant Management: "Manage Tenants" button -> `/admin/tenants`
- User Management: "Manage Users" button -> `/admin/users`

**Pending Approvals Alert** (if count > 0): Orange warning with "Review Pending Users" link

**Platform Admin - Users (`/admin/users`):**
- Filters: Search, Tenant dropdown, Status, Approval
- Table: Name, Email, Tenant (clickable), Role, Status, Approved, Actions
- Actions: Approve, Deactivate/Activate, Delete

**Platform Admin - Tenants (`/admin/tenants`):**
- "+ Create Tenant" button
- Table: Name, Slug, Users (count), Status, Created, Actions
- Actions: View Details, Edit, Add Admin, Deactivate/Activate, Delete
- Create Tenant: Organization Name (auto-generates slug) + Slug
- Add Admin: Full Name, Email, Password

### 10.6 Connector Setup Wizard

**Component:** `frontend/src/components/connectors/wizard/ConnectorWizard.tsx`

**5 Wizard Steps:**

| Step | Label | Description |
|------|-------|-------------|
| 1 | Connection | Verify connection - overview of process |
| 2 | Table | Select source table from connector |
| 3 | Columns | Map columns to semantic roles (Date, Entity, Volume) |
| 4 | Preview | Preview extracted data |
| 5 | Setup | Complete and extract entities |

**Step indicator:** Numbered circles (1-5), completed = green checkmark, current = blue highlight, connecting lines between steps.

---

## Appendix: Default Values Summary

| Setting | Default | Min | Max |
|---------|---------|-----|-----|
| Max upload size | 100 MB | — | Tenant-configurable |
| Dataset Redis TTL | 4 hours | — | — |
| Preprocessed data TTL | 2 hours | — | — |
| Forecast results TTL | 1 hour | — | — |
| Forecast Horizon | 30 periods | 1 | 365 |
| Data Frequency | Daily | — | — |
| Confidence Level | 95% | 80% | 99% |
| ARIMA p | 1 | 0 | 5 |
| ARIMA d | 1 | 0 | 2 |
| ARIMA q | 1 | 0 | 5 |
| Prophet changepoint_prior_scale | 0.05 | 0.001 | 0.5 |
| Prophet seasonality_prior_scale | 10.0 | 0.01 | 100.0 |
| Yearly Seasonality | ON | — | — |
| Weekly Seasonality | ON | — | — |
| Daily Seasonality | OFF | — | — |
| CV Folds | 5 | 2 | 10 |
| CV Method | Rolling | — | — |
| CV Initial Train Size | 70% | 50% | 90% |
| Missing values method | Forward Fill | — | — |
| Outlier detection method | IQR | — | — |
| Outlier IQR threshold | 1.5 | — | — |
| Outlier action | Cap Values | — | — |
| Duplicate handling | Keep First | — | — |
| Time aggregation frequency | Monthly | — | — |
| Time aggregation method | Sum | — | — |
| Results table page size | 50 rows | — | — |
| Primary brand color | #2563eb | — | — |
| Secondary brand color | #1e40af | — | — |
| Accent brand color | #3b82f6 | — | — |

---

## Appendix: Key Component File Paths

### Frontend Pages
| Page | File Path |
|------|-----------|
| Login | `frontend/src/app/[tenant]/login/page.tsx` |
| Register | `frontend/src/app/[tenant]/register/page.tsx` |
| Dashboard | `frontend/src/app/[tenant]/dashboard/page.tsx` |
| Data Upload | `frontend/src/app/[tenant]/data/page.tsx` |
| Connectors | `frontend/src/app/[tenant]/connectors/page.tsx` |
| Preprocessing | `frontend/src/app/[tenant]/preprocessing/page.tsx` |
| Forecast | `frontend/src/app/[tenant]/forecast/page.tsx` |
| Results | `frontend/src/app/[tenant]/results/page.tsx` |
| Diagnostics | `frontend/src/app/[tenant]/diagnostics/page.tsx` |
| Settings | `frontend/src/app/[tenant]/settings/page.tsx` |
| User Management | `frontend/src/app/[tenant]/settings/users/page.tsx` |
| Groups | `frontend/src/app/[tenant]/settings/groups/page.tsx` |
| Connector RLS | `frontend/src/app/[tenant]/settings/connectors/page.tsx` |
| Branding | `frontend/src/app/[tenant]/settings/branding/page.tsx` |
| Platform Admin | `frontend/src/app/(admin)/admin/page.tsx` |
| Admin Users | `frontend/src/app/(admin)/admin/users/page.tsx` |
| Admin Tenants | `frontend/src/app/(admin)/admin/tenants/page.tsx` |

### Frontend Components
| Component | File Path |
|-----------|-----------|
| Sidebar | `frontend/src/components/layout/Sidebar.tsx` |
| Header | `frontend/src/components/layout/Header.tsx` |
| FileUploader | `frontend/src/components/data/FileUploader.tsx` |
| ConnectorPanel | `frontend/src/components/data/ConnectorPanel.tsx` |
| SampleDataLoader | `frontend/src/components/data/SampleDataLoader.tsx` |
| MethodSelector | `frontend/src/components/forecast/MethodSelector.tsx` |
| ForecastSettings | `frontend/src/components/forecast/ForecastSettings.tsx` |
| ARIMASettings | `frontend/src/components/forecast/ARIMASettings.tsx` |
| ETSSettings | `frontend/src/components/forecast/ETSSettings.tsx` |
| ProphetSettings | `frontend/src/components/forecast/ProphetSettings.tsx` |
| RegressorSelector | `frontend/src/components/forecast/RegressorSelector.tsx` |
| CrossValidationSettings | `frontend/src/components/forecast/CrossValidationSettings.tsx` |
| ForecastProgress | `frontend/src/components/forecast/ForecastProgress.tsx` |
| ForecastResults | `frontend/src/components/forecast/ForecastResults.tsx` |
| BatchForecastResults | `frontend/src/components/forecast/BatchForecastResults.tsx` |
| ForecastChart | `frontend/src/components/results/ForecastChart.tsx` |
| MetricsCards | `frontend/src/components/results/MetricsCards.tsx` |
| ResultsTable | `frontend/src/components/results/ResultsTable.tsx` |
| ExportPanel | `frontend/src/components/results/ExportPanel.tsx` |
| ResidualChart | `frontend/src/components/diagnostics/ResidualChart.tsx` |
| ACFChart | `frontend/src/components/diagnostics/ACFChart.tsx` |
| QualityGauge | `frontend/src/components/diagnostics/QualityGauge.tsx` |
| SeasonalityPanel | `frontend/src/components/diagnostics/SeasonalityPanel.tsx` |
| ModelParametersPanel | `frontend/src/components/diagnostics/ModelParametersPanel.tsx` |
| ModelComparisonTable | `frontend/src/components/diagnostics/ModelComparisonTable.tsx` |
| MissingValuesHandler | `frontend/src/components/preprocessing/MissingValuesHandler.tsx` |
| OutlierHandler | `frontend/src/components/preprocessing/OutlierHandler.tsx` |
| DuplicateHandler | `frontend/src/components/preprocessing/DuplicateHandler.tsx` |
| ValueReplacer | `frontend/src/components/preprocessing/ValueReplacer.tsx` |
| TimeAggregator | `frontend/src/components/preprocessing/TimeAggregator.tsx` |
| ConnectorWizard | `frontend/src/components/connectors/wizard/ConnectorWizard.tsx` |

### Backend Endpoints
| Module | File Path |
|--------|-----------|
| Auth | `backend/app/api/v1/endpoints/auth.py` |
| Datasets | `backend/app/api/v1/endpoints/datasets.py` |
| Preprocessing | `backend/app/api/v1/endpoints/preprocessing.py` |
| Forecast | `backend/app/api/v1/endpoints/forecast.py` |
| Results | `backend/app/api/v1/endpoints/results.py` |
| Diagnostics | `backend/app/api/v1/endpoints/diagnostics.py` |
| Connectors | `backend/app/api/v1/endpoints/connectors.py` |
| Admin | `backend/app/api/v1/endpoints/admin.py` |
| Users | `backend/app/api/v1/endpoints/users.py` |
| Groups | `backend/app/api/v1/endpoints/groups.py` |

### Backend Services
| Service | File Path |
|---------|-----------|
| Dataset Service | `backend/app/services/dataset_service.py` |
| Preprocessing Service | `backend/app/services/preprocessing_service.py` |
| Forecast Service | `backend/app/services/forecast_service.py` |
| Results Service | `backend/app/services/results_service.py` |
| Diagnostics Service | `backend/app/services/diagnostics_service.py` |
| Connector Service | `backend/app/services/connector_service.py` |
| RLS Service | `backend/app/services/rls_service.py` |

### Forecasting Models
| Model | File Path |
|-------|-----------|
| ARIMA | `backend/app/forecasting/arima.py` |
| ETS | `backend/app/forecasting/ets.py` |
| Prophet | `backend/app/forecasting/prophet_forecaster.py` |
| Metrics | `backend/app/forecasting/metrics.py` |
