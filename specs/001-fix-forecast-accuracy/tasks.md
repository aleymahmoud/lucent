# Tasks: Fix Forecast Accuracy

**Input**: Design documents from `/specs/001-fix-forecast-accuracy/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/)

**Tests**: Limited. Only the new shared utilities (frequency detector, CV engine) require pytest coverage per the research doc. No frontend tests.

**Organization**: Tasks are grouped by user story (P1 stories first as MVP).

## Format: `[TaskID] [P?] [Story?] Description with file path`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US1..US7 maps to user stories in [spec.md](./spec.md)

---

## Phase 1: Setup (Shared Infrastructure)

- [ ] T001 Add `Q` and `Y` values to `ForecastFrequency` enum in `backend/app/schemas/forecast.py`
- [ ] T002 [P] Add `frequency_auto_detect: bool = True` to `ForecastRequest` in `backend/app/schemas/forecast.py`
- [ ] T003 [P] Add `detected_frequency`, `detected_seasonal_period`, `warnings` fields to `ForecastResultResponse` in `backend/app/schemas/forecast.py`
- [ ] T004 [P] Add `FrequencyDetectionResponse` schema to `backend/app/schemas/forecast.py`
- [ ] T005 [P] Extend `frontend/src/types/forecast.ts` with `FrequencyDetectionResponse`, `CrossValidationResult`, new optional fields on `ForecastResult`
- [ ] T006 [P] Register new utilities in `docs/shared-registry.md` (frequency detector, CV engine, warning builder)

---

## Phase 2: Foundational (Blocking Prerequisites)

**CRITICAL**: These utilities are used by multiple user stories. They must be in place before story implementation.

- [ ] T007 Create frequency detector module at `backend/app/forecasting/frequency.py` implementing `detect_frequency(dates: pd.DatetimeIndex) -> tuple[str, int]` per Decision 1 in research.md
- [ ] T008 [P] Create data validator module at `backend/app/forecasting/data_validator.py` implementing `validate_for_method(series, method, seasonal_period)` returning `DataValidationResult` — includes min-data checks, zero-variance check, irregular-intervals check, alternative-method suggestion
- [ ] T009 [P] Add `_suggest_alternative_methods(n_obs, s)` helper to `backend/app/forecasting/data_validator.py` per Decision 5 in research.md
- [ ] T010 Create cross-validation engine at `backend/app/forecasting/cross_validation.py` with `CVRunResult` dataclass and `run_cv(series, forecaster_factory, folds, method, initial_train_size, horizon) -> CVRunResult` supporting rolling + expanding modes per Decision 4
- [ ] T011 [P] Add pytest coverage for frequency detector at `backend/tests/forecasting/test_frequency.py` — all 5 buckets, edge overlaps, single-row/two-row defaults
- [ ] T012 [P] Add pytest coverage for CV engine at `backend/tests/forecasting/test_cross_validation.py` — rolling window slides correctly, expanding window grows correctly, fold-count reduction when data too short
- [ ] T013 [P] Add pytest coverage for data validator at `backend/tests/forecasting/test_data_validator.py` — each method minimum, suggested alternative correctness

**Checkpoint**: Utilities exist, are tested, and are ready to be wired into `forecast_service.py`.

---

## Phase 3: User Story 1 — Frequency auto-detect (Priority: P1) 🎯 MVP

**Goal**: Forecast runs on daily data pick up "Daily" automatically and produce a day-by-day horizon.

**Independent Test**: Upload a 90-row daily dataset, leave auto-detect on, run Prophet horizon=14, confirm 14 daily predictions.

### Backend

- [ ] T014 [US1] In `backend/app/services/forecast_service.py::_get_forecast_data()`, after loading the series, call `detect_frequency()` and return detection result alongside the series
- [ ] T015 [US1] In `backend/app/services/forecast_service.py::run_forecast()`, if `request.frequency_auto_detect` is True, override `request.frequency` with detected frequency; if False but detected differs, add warning "Selected frequency X does not match detected Y"
- [ ] T016 [US1] Pass detected `seasonal_period` through to the forecaster factory in `backend/app/services/forecast_service.py::_create_forecaster()` so ARIMA's `s`, ETS's `seasonal_periods`, and Prophet's `make_future_dataframe` all use it
- [ ] T017 [US1] Populate `result.detected_frequency` and `result.detected_seasonal_period` in `run_forecast()` response
- [ ] T018 [US1] Add `POST /api/v1/forecast/detect-frequency` endpoint in `backend/app/api/v1/endpoints/forecast.py` that returns `FrequencyDetectionResponse` without running a forecast

### Frontend

- [ ] T019 [P] [US1] Add "Auto-detect" toggle (default on) to `frontend/src/components/forecast/ForecastSettings.tsx` with a `detectedFrequency` hint that says "Detected: Daily" when the backend has returned detection results
- [ ] T020 [P] [US1] Add `detectFrequency()` API client call in `frontend/src/lib/api/forecast.ts` (or wherever forecast API functions live)
- [ ] T021 [US1] In `frontend/src/app/[tenant]/forecast/page.tsx`, call `/forecast/detect-frequency` when user selects a dataset+entity and show the result in the Settings panel

**Checkpoint**: Auto-detect works end-to-end. Can run Walkthrough 1 and 2 from quickstart.md.

---

## Phase 4: User Story 2 — Explicit regressors only (Priority: P1)

**Goal**: Eliminate indiscriminate regressor auto-detection that poisons Prophet.

**Independent Test**: Run Prophet on a dataset with a numeric `product_id` column without selecting any regressors; confirm `regressors_used: []` in model summary.

- [ ] T022 [US2] In `backend/app/services/forecast_service.py::_get_forecast_data()`, remove the implicit numeric-column auto-detection block (lines ~140-154). Only use columns explicitly listed in `request.regressor_columns`
- [ ] T023 [US2] Add validation: if `request.regressor_columns` contains a column not present in the dataset, return HTTP 400 with `"Regressor column X not found in dataset"`
- [ ] T024 [US2] Update `model_summary.regressors_used` in `backend/app/forecasting/prophet_forecaster.py` to reflect the actual list passed in (should now be empty when nothing selected)
- [ ] T025 [P] [US2] Confirm `frontend/src/components/forecast/RegressorSelector.tsx` still works unchanged — it was already sending explicit selections

**Checkpoint**: Walkthrough 4 from quickstart.md passes.

---

## Phase 5: User Story 3 — Minimum-data rejection (Priority: P1)

**Goal**: Reject forecast requests that fail per-method min-observation rules, with helpful error messages.

**Independent Test**: Run Prophet on a 12-row dataset; confirm HTTP 400 with message suggesting ETS or ARIMA.

- [ ] T026 [US3] In `backend/app/services/forecast_service.py::run_forecast()`, after loading the series and detecting frequency, call `data_validator.validate_for_method(series, request.method, seasonal_period)` before dispatching to the forecaster
- [ ] T027 [US3] If validation returns a blocking error, raise HTTPException(400) with the error message including suggested alternatives; do not update Redis status (or mark as FAILED)
- [ ] T028 [US3] Collect validator warnings into `result.warnings` for non-blocking advisories (zero-variance is blocking; irregular intervals is a warning)
- [ ] T029 [P] [US3] Mirror the same validation call in `backend/app/services/forecast_service.py::_run_batch_background()` so each entity is validated individually; failures go into `batch.results[entity].error`

**Checkpoint**: Walkthrough 5 from quickstart.md passes.

---

## Phase 6: User Story 4 — ARIMA fallback chain (Priority: P2)

**Goal**: When the default auto-ARIMA grid search fails, fall back progressively before surfacing an error.

**Independent Test**: Force a failing dataset through ARIMA and confirm a fallback model is used.

- [ ] T030 [US4] Refactor `backend/app/forecasting/arima.py::fit()` to wrap the primary fit attempt in try/except and cascade: (a) full auto-ARIMA -> (b) simpler non-seasonal (max.p=2, max.q=2, no seasonal) -> (c) ARIMA(1,1,1)
- [ ] T031 [US4] Add `fallback_level` field to `model_summary` output (0 = primary, 1 = simpler, 2 = ARIMA(1,1,1)) so the UI can display how the final model was reached
- [ ] T032 [US4] If all three attempts fail, raise with clear error suggesting ETS or Prophet instead
- [ ] T033 [P] [US4] Log each fallback step at INFO level with the data size and failure reason

**Checkpoint**: Walkthrough 6 from quickstart.md passes.

---

## Phase 7: User Story 5 — Cross-validation (Priority: P2)

**Goal**: Wire the CV engine into the forecast flow and populate `cv_results` in the response.

**Independent Test**: Run with CV enabled, 3 folds; confirm response contains per-fold metrics.

- [ ] T034 [US5] In `backend/app/services/forecast_service.py::run_forecast()`, after fitting the main model, if `request.cross_validation.enabled`, call `cross_validation.run_cv()` passing a forecaster factory closure
- [ ] T035 [US5] Convert `CVRunResult` into `CrossValidationResultResponse` and assign to `result.cv_results`
- [ ] T036 [US5] Persist `cv_results` JSON into `forecast_predictions.cv_results` column via the existing `_save_predictions_to_db()` path (no schema change needed)
- [ ] T037 [US5] Reduce `folds` automatically if `n_obs < folds * (initial_train + horizon)`; add warning "Requested N folds; reduced to M due to dataset size"
- [ ] T038 [P] [US5] In `frontend/src/components/forecast/ForecastResults.tsx`, add a "Cross-Validation" section showing in-sample vs CV metrics side-by-side when `cv_results` is present
- [ ] T039 [P] [US5] Verify `frontend/src/components/forecast/CrossValidationSettings.tsx` already builds the request correctly — no code change expected

**Checkpoint**: Walkthrough 7 from quickstart.md passes.

---

## Phase 8: User Story 6 — Proper ARIMA seasonal search (Priority: P2)

**Goal**: Joint (P, D, Q) grid search instead of hardcoded (1, 1, 1, s).

**Independent Test**: On a series with known seasonal structure, the detected order is not always (1,1,1,s).

- [ ] T040 [US6] Refactor `backend/app/forecasting/arima.py::_detect_seasonality()`: keep the ACF-based period detection but bump threshold to 0.4 and require the lag to repeat across at least 2 full cycles
- [ ] T041 [US6] Refactor `backend/app/forecasting/arima.py::_auto_arima()` to jointly search (p,d,q) × (P,D,Q) with bounds from Decision 2; pick the combo with lowest AIC; per-combination time budget to avoid runaway searches
- [ ] T042 [US6] Add early-termination: if no improvement in AIC for 20 consecutive combos, stop search and return current best
- [ ] T043 [US6] On joint-search timeout (> 30s per Decision 2), log and fall back to the narrower grid (max.P=max.Q=1)

**Checkpoint**: Manually verify using a synthetic series from Decision 2 in research.md.

---

## Phase 9: User Story 7 — Preventable-misconfiguration warnings (Priority: P3)

**Goal**: Surface detectable user mistakes as warnings before submission.

**Independent Test**: Enable yearly seasonality on 90-day data; see warning in response.

- [ ] T044 [US7] Extend `backend/app/forecasting/data_validator.py::validate_for_method()` to emit warnings for: yearly seasonality enabled with n < 730; weekly seasonality enabled with n < 14; daily seasonality enabled with n < 30
- [ ] T045 [US7] Extend `FrequencyDetectionResponse` warnings with the same rules so UI can show them before submit
- [ ] T046 [P] [US7] Create `frontend/src/components/forecast/ForecastWarnings.tsx` — renders a list of warning strings with an info/alert icon
- [ ] T047 [US7] Mount `ForecastWarnings` in `frontend/src/app/[tenant]/forecast/page.tsx` both pre-run (from /detect-frequency response) and post-run (from /run response.warnings)

**Checkpoint**: Walkthrough 8 from quickstart.md passes.

---

## Phase 10: Polish & Cross-cutting

- [ ] T048 [P] Generate synthetic benchmark datasets at `backend/scripts/generate_test_datasets.py` — produces the 20 series referenced in quickstart.md + SC-004
- [ ] T049 [P] Create benchmark runner at `backend/scripts/benchmark_forecasts.py` that runs old vs new pipeline across the 20 series and reports mean/median MAPE
- [ ] T050 Commit `baseline.json` in `specs/001-fix-forecast-accuracy/` with pre-fix MAPE values (run benchmark BEFORE merging, capture output)
- [ ] T051 After all phases complete, re-run benchmark and confirm ≥ 30% MAPE improvement (SC-004)
- [ ] T052 [P] Update `docs/bugs.md` with a note documenting the regressor auto-detect bug and its resolution
- [ ] T053 Manual walkthrough of all 10 quickstart.md scenarios end-to-end; record pass/fail
- [ ] T054 Build frontend (`cd frontend && npm run build`), restart PM2, verify Forecast page loads and all new UI elements render
- [ ] T055 Commit all changes with scope message; push to origin/main for deployment

---

## Dependencies

### Phase-level

- Phase 1 (Setup) can run in parallel with Phase 2 (Foundational)
- Phase 2 (Foundational) blocks Phases 3–9 — utilities must exist first
- Phase 3 (US1 frequency) should complete first as it enables meaningful testing of US6 (ARIMA seasonal) — other phases can run in parallel with each other after Phase 2
- Phase 10 (Polish) requires all earlier phases complete

### Task-level

- T007 (frequency detector) blocks T014, T018 (uses it)
- T008-T009 (data validator) blocks T026-T029 (uses it)
- T010 (CV engine) blocks T034-T037 (uses it)
- T014-T017 (frequency wiring) blocks T021 (UI needs backend)
- T030-T033 (ARIMA fallback) can proceed independently of T040-T043 (joint search); both modify `arima.py` so they must be sequenced by the implementer

### Parallel opportunities

Tasks marked [P] that can run concurrently within their phase:

- Phase 1: T002, T003, T004, T005, T006 (all different files)
- Phase 2: T008, T009 together (same file but independent functions); T011-T013 all [P] tests
- Phase 3: T019, T020 [P] frontend tasks
- Phase 7: T038, T039 [P] frontend tasks
- Phase 9: T046 [P] new component
- Phase 10: T048, T049 [P] scripts; T052 [P] docs

---

## MVP Scope

**Minimum viable increment**: Complete Phases 1–5 (Setup, Foundational, US1 frequency auto-detect, US2 regressor fix, US3 min-data validation).

These three user stories alone address the majority of the "bad accuracy" complaint:
- US1: Fixes misaligned forecasts when frequency mismatches (likely the single biggest reason user saw bad results)
- US2: Stops Prophet from being poisoned by ID columns
- US3: Blocks silent garbage forecasts on too-small datasets

US4 (ARIMA fallback), US5 (CV), US6 (seasonal search), US7 (warnings) are improvements layered on top.

---

## Task Count Summary

| Phase | Tasks |
|-------|-------|
| Setup | 6 |
| Foundational | 7 |
| US1 (frequency auto-detect) | 8 |
| US2 (explicit regressors) | 4 |
| US3 (min-data validation) | 4 |
| US4 (ARIMA fallback) | 4 |
| US5 (cross-validation) | 6 |
| US6 (seasonal search) | 4 |
| US7 (warnings) | 4 |
| Polish | 8 |
| **Total** | **55** |

Parallel-eligible: 26 tasks marked [P]
