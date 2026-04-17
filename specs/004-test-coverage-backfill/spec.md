# Feature Specification: Test Coverage Backfill + Forecast Benchmarks

**Feature Branch**: `004-test-coverage-backfill`
**Created**: 2026-04-17
**Status**: Draft
**Input**: User description: "Test coverage backfill and forecast benchmarks — pytest for services, integration tests for endpoints, synthetic dataset benchmark runner"

## Background Context

After three feature specs the backend has real, load-bearing logic spread across ~25 service and endpoint modules. Automated test coverage is 37 tests — all from specs 001 and 002 — concentrated on three forecasting utilities (frequency, data_validator, cross_validation, residual_tests). Everything else is effectively untested: the forecast service itself, the forecasters' fit/predict paths, the preprocessing service, the diagnostics service, the results service, the Excel/report exporters, the audit service, the admin endpoints, and the preprocessing endpoints.

Alongside unit and integration tests, the benchmark runner originally scoped for spec 001 Phase 10 was skipped. A proper benchmark is the only way to quantify whether our accuracy fixes actually improved forecasts on a diverse dataset — and to guard against regressions in future changes.

This feature closes both gaps.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Core forecast pipeline is regression-tested (Priority: P1)

As a developer, when I touch `forecast_service.py` or any of the three forecasters, I want a pytest suite that fails loudly if I break the happy-path contract (fit succeeds, predictions come back with the right shape, metrics are finite).

**Why this priority**: The forecast pipeline is the app's core. An accidental regression (e.g., a bad refactor changing the residuals contract) would be silent without these tests.

**Independent Test**: Run `pytest tests/forecasting/` and `tests/services/test_forecast_service.py`. Confirm the ARIMA, ETS, and Prophet happy-path tests pass; confirm a deliberate break (e.g., return an empty predictions list from ARIMA.predict) causes a test to fail.

**Acceptance Scenarios**:

1. **Given** a synthetic 100-row daily series with known weekly seasonality, **When** `ARIMAForecaster.fit(y).predict(14)` is called, **Then** the output has 14 rows, finite values, lower ≤ value ≤ upper, and MAE/RMSE/MAPE are finite.
2. **Given** the same series, **When** `ETSForecaster.fit(y).predict(14)` is called, **Then** same shape + finiteness guarantees hold.
3. **Given** the same series and CmdStan is available, **When** `ProphetForecaster.fit(y).predict(14)` is called, **Then** same guarantees hold. (Skip with marker when CmdStan is missing.)
4. **Given** a request with `cross_validation.enabled=True`, **When** `ForecastService.run_forecast` completes, **Then** `result.cv_results` is populated with the requested number of folds (or fewer with a warning).

---

### User Story 2 — Residual persistence is contract-tested (Priority: P1)

As a developer, when I touch residual handling, I want a test that asserts the full residuals array round-trips through `forecast_service` → Redis serialization → `diagnostics_service._extract_residuals` without data loss.

**Why this priority**: This was the single biggest bug fixed in spec 002. If it regresses, diagnostics tests silently start running on synthetic data again.

**Independent Test**: Unit test: build a `ForecastResultResponse` with a known 100-element residuals list; serialize it to JSON; deserialize; pass to `DiagnosticsService._extract_residuals`; assert length == 100 and values equal within float precision.

**Acceptance Scenarios**:

1. **Given** a ForecastResultResponse with residuals=[…], **When** serialized to JSON and back, **Then** the residuals field survives intact.
2. **Given** a legacy ForecastResultResponse with no residuals field, **When** `_extract_residuals` runs, **Then** it returns None (not synthetic data).
3. **Given** a response with residuals in the legacy `diagnostics["residuals"]` location, **When** `_extract_residuals` runs, **Then** the array is still recovered.

---

### User Story 3 — Preprocessing service is covered (Priority: P2)

As a developer, the preprocessing service has had many per-entity bugs fixed in spec 002; I want tests that pin the corrected behaviour so they don't silently regress.

**Why this priority**: Preprocessing was heavily re-engineered. Core methods (missing-value imputation, duplicate handling, outlier detection, aggregation) should each have at least one happy-path test and one edge case.

**Acceptance Scenarios**:

1. Missing values: mean imputation on a dataframe with ~10% NaNs leaves zero NaNs in the target column.
2. Duplicates: `drop_duplicates` with subset=[date] on a df with 5 duplicate date pairs reduces row count by 5.
3. Outliers: IQR method with threshold=1.5 on `[1,2,3,4,5,100]` flags 100.
4. Aggregation: monthly aggregation of 365 daily rows produces 12 monthly rows.
5. Per-entity grouping: missing-value imputation with `entity_column` set computes mean per entity (asserted via two entities with different means).

---

### User Story 4 — API endpoints are integration-tested (Priority: P2)

As a developer, I want at least one end-to-end test per endpoint family that boots FastAPI in test mode, authenticates, hits the endpoint, and asserts a 200 response with the expected shape.

**Why this priority**: Unit tests prove the service is correct in isolation. Integration tests prove the wiring (routes, dependencies, auth, serialization) is correct.

**Acceptance Scenarios**:

1. POST `/api/v1/forecast/run` with a valid minimal body returns 200 with `status` and `predictions` fields.
2. GET `/api/v1/results/{id}` returns 404 for an unknown UUID.
3. GET `/api/v1/audit` without tenant-admin role returns 403.
4. POST `/api/v1/preprocessing/{id}/missing` with an unknown dataset returns 404.

---

### User Story 5 — Exporters produce valid output (Priority: P2)

As a developer, the Excel and HTML report exporters should produce parse-able output — not just any bytes.

**Acceptance Scenarios**:

1. `export_single(result).getvalue()` opens as a valid xlsx (via `openpyxl.load_workbook`) with at least 3 sheets.
2. `export_batch(batch_result).getvalue()` opens as valid xlsx with one sheet per entity plus Summary + All_Data.
3. `render_html(forecast, diagnostics)` returns HTML containing the forecast method, entity id, and at least one test result row.

---

### User Story 6 — Forecast accuracy is benchmarked (Priority: P2)

As the platform operator, I want a scripted benchmark across 20 synthetic datasets with diverse properties so I can measure out-of-sample MAPE and catch regressions when we change forecasting logic.

**Why this priority**: Spec 001's SC-004 asked for this (30% MAPE reduction target) but was deferred. Running it now gives us a baseline. Future specs can compare against that baseline.

**Independent Test**: Run `python backend/scripts/benchmark_forecasts.py`. Confirm it produces `specs/004-test-coverage-backfill/baseline.json` with per-dataset per-method MAPE + overall averages.

**Acceptance Scenarios**:

1. **Given** a known synthetic dataset generator, **When** the benchmark runs, **Then** it fits ARIMA + ETS + Prophet (when available) on each of 20 synthetic series and records MAPE via cross-validation.
2. **Given** the benchmark finishes, **When** I open the output JSON, **Then** it contains per-dataset per-method records and per-method averages.
3. **Given** a regression test harness exists (P3), **When** CI runs, **Then** it fails if average MAPE is >10% worse than the stored baseline.

---

### User Story 7 — CI-friendly test runner (Priority: P3)

As a developer, I want one command (`pytest backend/tests/`) to run every test in under 60 seconds (unit tests; integration tests are a separate target).

**Why this priority**: Fast feedback loop. Without separation, integration-test slowness pollutes the dev inner loop.

**Acceptance Scenarios**:

1. `pytest backend/tests/ -m "not integration"` completes in under 60 seconds on a typical dev machine.
2. `pytest backend/tests/ -m integration` runs the integration tests separately (may take longer).
3. Coverage report (via `pytest --cov=backend/app`) reports at least 60% statement coverage across the backend.

---

### Edge Cases

- Prophet tests skip cleanly when CmdStan isn't installed (pytest marker).
- Integration tests that hit real Redis: skip when Redis env var not set, OR use an in-memory fake.
- Benchmark running in CI without network access: uses seeded RNG so outputs are deterministic.
- Tests that depend on PostgreSQL: use a schema-level rollback per test (SQLAlchemy async session fixture with savepoint).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST have at least one happy-path pytest per forecaster class (ARIMA, ETS, Prophet) covering fit + predict.
- **FR-002**: System MUST have a pytest for `ForecastService.run_forecast` that exercises the full pipeline with CV enabled.
- **FR-003**: System MUST have tests that assert residuals round-trip through serialization intact.
- **FR-004**: System MUST have pytests for each preprocessing method (missing values, duplicates, outliers, aggregation, value replacement, conditional replacement).
- **FR-005**: System MUST have integration tests for at least one endpoint per router (forecast, results, diagnostics, preprocessing, audit, users).
- **FR-006**: System MUST have tests that verify Excel exports open as valid xlsx files and HTML reports contain expected sections.
- **FR-007**: System MUST provide a benchmark script that runs each forecast method on 20 synthetic datasets and records MAPE.
- **FR-008**: System MUST persist the benchmark baseline at `specs/004-test-coverage-backfill/baseline.json`.
- **FR-009**: Test suite MUST distinguish unit (`backend/tests/unit/` or unmarked) from integration (`-m integration`) via pytest markers.
- **FR-010**: pytest command MUST produce coverage output showing at least 60% statement coverage of `backend/app/services/` and `backend/app/forecasting/`.

### Key Entities

- **SyntheticDataset**: generator config — seed, length, frequency, trend, seasonal_period, noise_scale.
- **BenchmarkResult**: per-dataset per-method record — {dataset_id, method, cv_mape, cv_mae, cv_rmse, fit_time_ms, predict_time_ms}.
- **BenchmarkSummary**: aggregate report — {method, avg_mape, avg_mae, avg_rmse, success_rate}.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `pytest backend/tests/ -m "not integration"` completes in under 60 seconds and passes with zero failures.
- **SC-002**: Statement coverage of `backend/app/forecasting/` is at least 70%.
- **SC-003**: Statement coverage of `backend/app/services/` is at least 50% (higher where business logic is concentrated).
- **SC-004**: Integration tests exercise at least one endpoint from each of the 6 major routers.
- **SC-005**: Benchmark script produces a stable baseline with identical numbers across two consecutive runs given the same random seed.
- **SC-006**: Prophet-dependent tests skip cleanly (not fail) when CmdStan is unavailable.
- **SC-007**: Benchmark completes in under 10 minutes on a dev laptop for all 20 synthetic datasets × 3 methods (ARIMA, ETS, Prophet-if-available).

## Assumptions

- pytest and pytest-asyncio are already installed (confirmed in specs 001 and 002 test runs). Adding `pytest-cov` and `httpx` as dev dependencies is acceptable; both are small pure-Python packages.
- A lightweight integration-test strategy is fine: spin up the FastAPI app via `TestClient`, stub Redis with `fakeredis` if available (optional — tests can skip when Redis is unreachable).
- PostgreSQL integration tests use the existing Neon dev DB with per-test transaction rollback; no separate test DB is provisioned.
- "Coverage" is measured with `coverage.py` via `pytest --cov`; we don't need branch coverage for the initial MVP.
- The synthetic benchmark uses `numpy.random.default_rng(seed=42)` for determinism; no real-world datasets are required.
- Benchmark output file can live in the spec folder (`specs/004-test-coverage-backfill/baseline.json`) since it's tied to the feature's purpose.
