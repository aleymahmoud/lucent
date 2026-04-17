# Shared Registry

> Single source of truth for all shared utilities, constants, mappings, and helpers.
> BEFORE creating anything reusable, search this file first.
> AFTER creating something reusable, add it here.

## Utility Functions

| Name | File Path | Purpose | Created By |
|------|-----------|---------|------------|
| `cn()` | `frontend/src/lib/utils.ts` | Merges Tailwind class names conditionally | Reem |
| `detect_frequency(dates)` | `backend/app/forecasting/frequency.py` | Auto-detect time series frequency (D/W/M/Q/Y) from datetime index; returns (freq_code, seasonal_period) | Spec 001 |
| `validate_for_method(series, method, seasonal_period)` | `backend/app/forecasting/data_validator.py` | Per-method min-data + zero-variance + irregular-intervals validation; returns DataValidationResult | Spec 001 |
| `run_cv(series, forecaster_factory, folds, method, initial_train_size, horizon)` | `backend/app/forecasting/cross_validation.py` | Rolling/expanding window CV engine returning CVRunResult | Spec 001 |
| `ljung_box(residuals, lags=None)` | `backend/app/forecasting/residual_tests.py` | Ljung-Box autocorrelation test returning ResidualTestResult | Spec 002 |
| `breusch_pagan(residuals, fitted)` | `backend/app/forecasting/residual_tests.py` | Breusch-Pagan heteroscedasticity test returning ResidualTestResult | Spec 002 |
| `shapiro_wilk(residuals)` | `backend/app/forecasting/residual_tests.py` | Shapiro-Wilk normality test returning ResidualTestResult (skipped if n > 5000) | Spec 002 |
| `AuditService.list_events(db, **filters)` | `backend/app/services/audit_service.py` | Paginated, filtered audit log query for a tenant | Spec 003 P1 |
| `AuditService.export_csv(db, **filters)` | `backend/app/services/audit_service.py` | Stream filtered audit events as CSV (capped at 10k rows) | Spec 003 P1 |

## Shared Constants

| Name | File Path | Purpose | Created By |
|------|-----------|---------|------------|

## Type Definitions

| Name | File Path | Purpose | Created By |
|------|-----------|---------|------------|
| Wizard types (`WizardTable`, `WizardColumn`, `WizardDateRange`, `WizardEntity`, `WizardSetupResponse`, `WizardImportResponse`, `WizardPreviewResponse`, `WizardColumnMap`, `WizardData`) | `frontend/src/types/wizard.ts` | All TypeScript types for the connector wizard and data-source import flows | Yoki |

## Pydantic Schemas (Backend)

| Name | File Path | Purpose | Created By |
|------|-----------|---------|------------|

## API Endpoints Registry

| Name | File Path | Purpose | Created By |
|------|-----------|---------|------------|
| API client | `frontend/src/lib/api/client.ts` | Axios instance with interceptors | Yoki |
| API endpoints | `frontend/src/lib/api/endpoints.ts` | All 68 endpoint definitions | Yoki |
| `wizardApi` | `frontend/src/lib/api/wizard-endpoints.ts` | Typed API calls for connector wizard (listTables, listColumns, preview, dateRange, setup) | Yoki |
| `dataSourceApi` | `frontend/src/lib/api/wizard-endpoints.ts` | Typed API calls for data source user import (getEntities, importData) | Yoki |

## Services / Backends

| Name | File Path | Purpose | Created By |
|------|-----------|---------|------------|
| `StorageBackend` | `backend/app/services/storage/base.py` | Abstract interface for file storage backends | Omar |
| `S3Backend` | `backend/app/services/storage/s3_backend.py` | S3/CranL storage implementation (boto3 + asyncio.to_thread) | Omar |
| `LocalBackend` | `backend/app/services/storage/local_backend.py` | Local filesystem storage for development (aiofiles) | Omar |
| `get_storage_backend()` | `backend/app/services/storage/factory.py` | Singleton factory — returns S3Backend or LocalBackend based on config | Omar |
| `reset_storage_backend()` | `backend/app/services/storage/factory.py` | Destroy singleton (test teardown only) | Omar |

## Celery Tasks

| Name | File Path | Purpose | Created By |
|------|-----------|---------|------------|
| `cleanup_expired_snapshots` | `backend/app/tasks/retention.py` | Daily Celery beat task (03:00 UTC) — deletes expired DataSnapshot S3 files and marks rows as EXPIRED. Forecast data is never touched. Batched (RETENTION_BATCH_SIZE), idempotent. | Nabil |

## Mappings / Config Objects

| Name | File Path | Purpose | Created By |
|------|-----------|---------|------------|

## Deployment

| Name | File Path | Purpose | Created By |
|------|-----------|---------|------------|
| `backend/Dockerfile` | `backend/Dockerfile` | Dockerfile for backend: installs ODBC Driver 17 (Debian 12), CmdStan, then Python dependencies. Used by `cranl apps create --build-type dockerfile` | Tarek |
| `backend/.dockerignore` | `backend/.dockerignore` | Excludes pycache, .env, tests, and build artifacts from the Docker image | Tarek |
| `frontend/nixpacks.toml` | `frontend/nixpacks.toml` | Explicit nixpacks config for CranL frontend deploy — sets build (`npm run build`) and start (`npm start`) commands | Tarek |
| `.env.cranl.example` | `.env.cranl.example` | Annotated environment variable template for CranL production deployment, covering DB, Redis, S3, security, and Stack Auth | Tarek |
| `DEPLOY.md` | `DEPLOY.md` | Step-by-step CranL deployment guide including all CLI commands, migration, rollback, and local dev instructions | Tarek |

---

### Rules
1. If your function could be used by another teammate → register it here
2. If you need a utility → search this file before writing your own
3. Duplicates found by Farida (QA) are **blocking issues**
4. Conflicts resolved by Reem (Architect)
