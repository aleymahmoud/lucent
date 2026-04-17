# Tasks: Test Coverage Backfill + Benchmarks

**Input**: Design documents from `/specs/004-test-coverage-backfill/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md)

## Format: `[TaskID] [P?] [Story?] Description with file path`

---

## Phase 1: Setup & shared fixtures (P1)

- [ ] T001 Create `backend/tests/data/synthetic.py` with dataset generators (daily weekly-seasonal, monthly yearly-seasonal, pure trend, random walk, constant-plus-outliers)
- [ ] T002 [P] Configure pytest markers in `backend/pyproject.toml` or `pytest.ini`: register `integration`; set asyncio_mode
- [ ] T003 [P] Add dev deps to `backend/requirements-dev.txt`: `pytest-cov`, `httpx`, `fakeredis`

---

## Phase 2: US1 — Forecaster happy-path tests (P1)

- [ ] T004 [P] [US1] `backend/tests/unit/forecasting/test_arima.py` — fit + predict on synthetic daily weekly-seasonal; assert predictions shape, finite values, bounds order, metrics finite
- [ ] T005 [P] [US1] `backend/tests/unit/forecasting/test_ets.py` — same shape of tests for ETS
- [ ] T006 [P] [US1] `backend/tests/unit/forecasting/test_prophet.py` — same, guarded by CmdStan-available skip marker
- [ ] T007 [US1] Add test for ARIMA fallback chain: inject a synthetic failure path (mock the primary fit to raise) and confirm `fallback_level` advances

---

## Phase 3: US1 — ForecastService integration test (P1)

- [ ] T008 [US1] `backend/tests/unit/services/test_forecast_service.py` — build a minimal ForecastRequest, stub Redis with fakeredis + a seeded dataset in memory, run `ForecastService.run_forecast`, assert status=COMPLETED + predictions populated + cv_results populated when requested
- [ ] T009 [US1] Same file: assert `detected_frequency` + `detected_seasonal_period` are populated
- [ ] T010 [US1] Same file: assert `model_summary.residuals` is a non-empty list after completion

---

## Phase 4: US2 — Residual persistence contract (P1)

- [ ] T011 [US2] `backend/tests/unit/schemas/test_forecast_schemas.py` — round-trip a ForecastResultResponse with residuals through `model_dump(mode="json")` → JSON → `model_validate(...)`; assert residuals survive within float precision
- [ ] T012 [US2] Same file: legacy shape where residuals is missing → `DiagnosticsService._extract_residuals` returns None (not synthetic data)
- [ ] T013 [US2] Same file: legacy location `model_summary.diagnostics["residuals"]` is still picked up

---

## Phase 5: US3 — Preprocessing service tests (P2, deferred)

- [ ] T014 [P] [US3] `backend/tests/unit/services/test_preprocessing_service.py` — one happy-path test per method: missing values (mean), duplicates (drop), outliers (IQR), aggregation (monthly), value replacement
- [ ] T015 [P] [US3] Same file: per-entity grouping asserted for mean imputation (two entities with different means)

---

## Phase 6: US4 — Endpoint integration tests (P2, deferred)

- [ ] T016 [P] [US4] `backend/tests/integration/conftest.py` — TestClient fixture + auth helper that issues a valid JWT for a seeded user
- [ ] T017 [US4] `backend/tests/integration/test_forecast_endpoints.py` — POST /forecast/run happy path
- [ ] T018 [US4] `backend/tests/integration/test_results_endpoints.py` — GET /results/{unknown} → 404
- [ ] T019 [US4] `backend/tests/integration/test_diagnostics_endpoints.py` — GET /diagnostics/{id} round-trip
- [ ] T020 [US4] `backend/tests/integration/test_audit_endpoints.py` — GET /audit without tenant-admin role → 403
- [ ] T021 [US4] `backend/tests/integration/test_preprocessing_endpoints.py` — POST /preprocessing/{unknown}/missing → 404
- [ ] T022 [US4] `backend/tests/integration/test_admin_endpoints.py` — GET /admin/stats returns expected shape

---

## Phase 7: US5 — Exporter tests (P2, deferred)

- [ ] T023 [P] [US5] `backend/tests/unit/services/test_excel_exporter.py` — export_single + export_batch produce valid xlsx (openpyxl.load_workbook succeeds; sheet names match expected)
- [ ] T024 [P] [US5] `backend/tests/unit/services/test_report_exporter.py` — render_html contains the method, entity_id, and at least one test result row

---

## Phase 8: US6 — Benchmark (P2, deferred)

- [ ] T025 [US6] `backend/scripts/benchmark_forecasts.py` — iterate 20 synthetic series × {ARIMA, ETS, Prophet-when-available}; CV MAPE per row; write `specs/004-test-coverage-backfill/baseline.json`
- [ ] T026 [US6] Output schema validation: the JSON structure matches `BenchmarkResult` + `BenchmarkSummary` from spec
- [ ] T027 [US6] Determinism check: two runs with seed=42 produce identical numbers

---

## Phase 9: US7 — Coverage + CI separation (P3, deferred)

- [ ] T028 [P] [US7] Add `pytest --cov` config to pyproject.toml
- [ ] T029 [P] [US7] Document commands in README or `docs/testing.md`

---

## Phase 10: Polish + commit (P1 final)

- [ ] T030 Run `pytest backend/tests/unit/ -v` — confirm zero failures
- [ ] T031 Commit scoped changes; leave push to the user

---

## MVP Scope (P1)

**Phases 1 through 4 + Phase 10** = 13 tasks, ~15 new tests.

Delivers:
- Synthetic dataset generators (reused by P2 benchmark later)
- Happy-path tests per forecaster
- ForecastService end-to-end test with CV
- Residual-persistence round-trip contract

Phases 5-9 stay as defined tasks for later increments.

---

## Task Count Summary

| Phase | Tasks | Priority | In MVP |
|-------|-------|----------|--------|
| 1 Setup | 3 | P1 | Yes |
| 2 Forecaster tests | 4 | P1 | Yes |
| 3 Forecast service | 3 | P1 | Yes |
| 4 Residual contract | 3 | P1 | Yes |
| 5 Preprocessing tests | 2 | P2 | — |
| 6 Endpoint integration | 7 | P2 | — |
| 7 Exporter tests | 2 | P2 | — |
| 8 Benchmark | 3 | P2 | — |
| 9 Coverage + CI | 2 | P3 | — |
| 10 Commit | 2 | P1 | Yes |
| **Total** | **31** | | **15 in MVP** |
