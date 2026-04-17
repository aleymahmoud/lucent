# Tasks: Results & Diagnostics Parity

**Input**: Design documents from `/specs/002-results-and-diagnostics/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/)

**Tests**: pytest coverage for `residual_tests.py` only — the rest is manual walkthrough per [quickstart.md](./quickstart.md).

**Organization**: Tasks grouped by user story. P1 stories (US1, US2) form the MVP and must ship together — persisting residuals unlocks most of the Diagnostics work, displaying CV results is a small but high-visibility change.

## Format: `[TaskID] [P?] [Story?] Description with file path`

- **[P]**: Parallel-eligible (different files, no dependencies)
- **[Story]**: US1..US10

---

## Phase 1: Setup (Shared Infrastructure)

- [ ] T001 Add `ModelCoefficient` schema to `backend/app/schemas/forecast.py`
- [ ] T002 [P] Add `ResidualTestResult` schema to `backend/app/schemas/diagnostics.py`
- [ ] T003 [P] Add `ForecastStatisticsResponse` schema to `backend/app/schemas/forecast.py`
- [ ] T004 [P] Update `ForecastResultResponse.model_summary` to allow `residuals: Optional[List[float]]` in Pydantic
- [ ] T005 [P] Update `ResidualAnalysisResponse` with `is_synthetic: bool` and `tests: List[ResidualTestResult]` fields in `backend/app/schemas/diagnostics.py`
- [ ] T006 [P] Add `ModelCoefficient`, `ResidualTestResult`, `ForecastStatistics` types to `frontend/src/types/index.ts`
- [ ] T007 [P] Register new backend utilities (`residual_tests.py`, `excel_exporter.py`, `report_exporter.py`) in `docs/shared-registry.md`

---

## Phase 2: Foundational (Blocking)

**Critical path**: Tasks in this phase unblock every user story — US2/US3/US4 all depend on residual persistence and test utilities.

- [ ] T008 Create `backend/app/forecasting/residual_tests.py` with three functions: `ljung_box(residuals, lags=None)`, `breusch_pagan(residuals, fitted)`, `shapiro_wilk(residuals)`; each returns a `ResidualTestResult` with plain-English interpretation
- [ ] T009 [P] Add pytest suite `backend/tests/forecasting/test_residual_tests.py` covering all 6 known-outcome scenarios in research Decision 7 (AR(1), white noise, homoscedastic, heteroscedastic, Gaussian, exponential)
- [ ] T010 In `backend/app/forecasting/arima.py::predict()`, extract full residuals array from `self.model.resid` and include it in `ForecastOutput.residuals` (already a field) — verify the existing field is actually propagated end-to-end
- [ ] T011 [P] Same for `backend/app/forecasting/ets.py::predict()` — use `self.model.resid`
- [ ] T012 [P] Same for `backend/app/forecasting/prophet_forecaster.py::predict()` — compute `y - yhat` for training periods from `self._df_train` and `merged`
- [ ] T013 In `backend/app/services/forecast_service.py::run_forecast()`, write the residuals array into `result.model_summary.residuals` (list of rounded floats, truncated to last 2000) before storing to Redis and DB
- [ ] T014 In `backend/app/forecasting/arima.py::predict()`, build the new coefficient list shape (estimate + SE + z-stat + p-value + significant) from `model.params/bse/tvalues/pvalues` and attach to `ForecastOutput.model_summary.coefficients`
- [ ] T015 [P] Same coefficient extraction in `backend/app/forecasting/ets.py::predict()` (handling the case where `bse/tvalues/pvalues` are missing — fall back to estimate-only)
- [ ] T016 [P] Prophet's `predict()` in `backend/app/forecasting/prophet_forecaster.py` sets `coefficients=None` (hyperparameter display instead)

**Checkpoint**: Residuals flow end-to-end. Coefficients carry SE/p-values for ARIMA and ETS.

---

## Phase 3: User Story 1 — CV results visible on Results (Priority: P1)

**Goal**: The cross-validation work from spec 001 becomes visible in the UI.

**Independent Test**: Walkthrough 1 passes.

- [ ] T017 [US1] Create `frontend/src/components/results/CrossValidationPanel.tsx` — renders when `cv_results` is populated; shows fold count, method, per-fold table, average row
- [ ] T018 [US1] Mount `CrossValidationPanel` in `frontend/src/app/[tenant]/results/page.tsx` below the metrics cards, conditional on `result.cv_results` existence
- [ ] T019 [US1] Update `frontend/src/components/results/MetricsCards.tsx` to optionally render a second value (CV average) alongside each in-sample metric

---

## Phase 4: User Story 2 — Real residuals drive diagnostics (Priority: P1)

**Goal**: Kill `np.random.normal` in diagnostics_service; use stored residuals.

**Independent Test**: Walkthrough 2 passes.

- [ ] T020 [US2] In `backend/app/services/diagnostics_service.py::get_residual_analysis()`, replace the residuals reconstruction block (lines 67-102) with: read `result.model_summary.residuals`; if null, set `is_synthetic=true` and return early with empty arrays
- [ ] T021 [US2] When residuals are available, compute Ljung-Box + Breusch-Pagan + Shapiro-Wilk via `residual_tests.py`, populate the `tests` array on the response
- [ ] T022 [US2] Add a `ResidualHistoricalBanner` inline in `frontend/src/app/[tenant]/diagnostics/page.tsx` — shown when `residuals.is_synthetic` is true

---

## Phase 5: User Story 3 — Missing residual plots and tests (Priority: P2)

**Goal**: Four plot types + three tests in the Residuals tab.

**Independent Test**: Walkthrough 3 passes.

- [ ] T023 [US3] Refactor `frontend/src/components/diagnostics/ResidualChart.tsx` to accept a `plotType` prop: `"timeseries" | "histogram" | "qq" | "acf"`; delegate to sub-components
- [ ] T024 [P] [US3] Create `frontend/src/components/diagnostics/ResidualTimeSeriesChart.tsx` — scatter + line + ±σ/±2σ reference bands
- [ ] T025 [P] [US3] Create `frontend/src/components/diagnostics/HistogramChart.tsx` — histogram + normal curve overlay + KDE line (use `d3` kernel density estimator or simple polynomial approximation; don't add a new library)
- [ ] T026 [P] [US3] Create `frontend/src/components/diagnostics/QQPlot.tsx` — theoretical vs sample quantiles with reference diagonal
- [ ] T027 [P] [US3] Existing `ACFChart.tsx` already covers ACF — add the plot-type selector outside it in the parent page
- [ ] T028 [US3] Create `frontend/src/components/diagnostics/ResidualTests.tsx` — renders the `tests` array from the response (3 rows: Ljung-Box / Breusch-Pagan / Shapiro-Wilk) with p-values and interpretations
- [ ] T029 [US3] Update `frontend/src/app/[tenant]/diagnostics/page.tsx` Residuals tab to use the plot-type selector + ResidualTests component

---

## Phase 6: User Story 4 — Coefficient significance (Priority: P2)

**Goal**: ARIMA/ETS coefficients show SE, z, p-value, significance flag.

**Independent Test**: Walkthrough 4 passes.

- [ ] T030 [US4] In `backend/app/services/diagnostics_service.py::get_model_parameters()`, read new-shape coefficient list from `model_summary.coefficients`; handle legacy Dict shape via a migration helper
- [ ] T031 [US4] Create `frontend/src/components/diagnostics/CoefficientTable.tsx` with columns Name / Estimate / Std. Error / Z-stat / P-value + "Not significant" badge for p > 0.05
- [ ] T032 [US4] Update `frontend/src/components/diagnostics/ModelParametersPanel.tsx` to render `CoefficientTable` for ARIMA/ETS; for Prophet render the hyperparameter panel (unchanged)

---

## Phase 7: User Story 5 — Forecast statistics panel (Priority: P2)

**Goal**: Six numbers (mean / median / min / max / IQR / avg interval width) on Results page.

**Independent Test**: Walkthrough 5 passes.

- [ ] T033 [US5] In `backend/app/services/results_service.py`, compute `ForecastStatisticsResponse` from the predictions in the stored result; add it to the `/results/{id}/summary` response
- [ ] T034 [US5] Create `frontend/src/components/results/ForecastStatsPanel.tsx` — 6 stat cards in a 3×2 grid
- [ ] T035 [US5] Mount `ForecastStatsPanel` in `frontend/src/app/[tenant]/results/page.tsx` Overview tab

---

## Phase 8: User Story 6 — Model comparison UI (Priority: P2)

**Goal**: Wire the existing backend `/diagnostics/compare` endpoint to a UI button.

**Independent Test**: Walkthrough 6 passes.

- [ ] T036 [US6] Create `frontend/src/components/diagnostics/ModelComparisonPanel.tsx` with method checkboxes + "Run Comparison" button + loading state + results table
- [ ] T037 [US6] Add `compareModels()` to `frontend/src/lib/api/endpoints.ts` — typed POST to `/diagnostics/compare`
- [ ] T038 [US6] Mount `ModelComparisonPanel` on `frontend/src/app/[tenant]/diagnostics/page.tsx` (new tab or collapsed section)

---

## Phase 9: User Story 7 — Chart controls (Priority: P3)

**Goal**: Line / Line+Points / Area selector, show-intervals toggle, range slider.

**Independent Test**: Walkthrough 7 passes.

- [ ] T039 [US7] Add plot-type selector + show-intervals checkbox to `frontend/src/components/results/ForecastChart.tsx`
- [ ] T040 [US7] Enable Plotly range slider when data length > 90 in `frontend/src/components/results/ForecastChart.tsx`

---

## Phase 10: User Story 8 — Table view modes (Priority: P3)

**Goal**: "Forecast Only" / "Historical + Forecast" / "Full Data" selector.

**Independent Test**: Walkthrough 8 passes.

- [ ] T041 [US8] Extend `/results/{id}/data` backend endpoint in `backend/app/api/v1/endpoints/results.py` to accept `view_mode=forecast|both|full` query param; return appropriate rows
- [ ] T042 [US8] Add view-mode selector to `frontend/src/components/results/ResultsTable.tsx`; re-fetch on change
- [ ] T043 [US8] Pass through historical rows when `view_mode != forecast` — backend reads from `forecast_predictions` or refetches from the dataset (use whichever is already available in the service)

---

## Phase 11: User Story 9 — Excel export (Priority: P3)

**Goal**: Multi-sheet .xlsx for single forecast and batch.

**Independent Test**: Walkthrough 9 passes.

- [ ] T044 [US9] Create `backend/app/services/excel_exporter.py` with `export_single(result) -> BytesIO` and `export_batch(batch_result) -> BytesIO` using `openpyxl`
- [ ] T045 [US9] Add `GET /results/{forecast_id}/export/excel` endpoint in `backend/app/api/v1/endpoints/results.py` that streams the BytesIO
- [ ] T046 [US9] Add `GET /results/batch/{batch_id}/export/excel` endpoint for batch
- [ ] T047 [US9] Add "Download Excel" button to `frontend/src/components/results/ExportPanel.tsx` with a dropdown (Single Entity / All Entities when in batch context)

---

## Phase 12: User Story 10 — Diagnostics export (Priority: P3)

**Goal**: HTML (and optionally PDF) diagnostics report.

**Independent Test**: Walkthrough 10 passes.

- [ ] T048 [US10] Create `backend/app/services/report_exporter.py` with `export_html(forecast_id, diagnostics) -> str` that assembles a self-contained HTML with embedded Plotly images (base64 PNG via kaleido if available, else SVG)
- [ ] T049 [US10] Optional: `export_pdf()` using weasyprint if installed; return 501 otherwise
- [ ] T050 [US10] Add `GET /diagnostics/{forecast_id}/export?format=html|pdf` endpoint in `backend/app/api/v1/endpoints/diagnostics.py`
- [ ] T051 [US10] Create `frontend/src/components/diagnostics/DiagnosticsExportPanel.tsx` — format dropdown + download button

---

## Phase 13: Polish & Benchmarks

- [ ] T052 [P] Create `backend/scripts/benchmark_diagnostics.py` — generates 20 synthetic datasets (mix of white-noise, AR(1), heteroscedastic, non-normal), fits models, captures Ljung-Box p-values; confirms ≥90% of values differ from what the old synthetic path would have produced
- [ ] T053 [P] Update `docs/bugs.md` to document the residual-synthesis bug and its resolution
- [ ] T054 [P] Update `docs/shared-registry.md` with all new utilities (already done in T007, re-verify before commit)
- [ ] T055 Run all quickstart walkthroughs end-to-end, mark pass/fail
- [ ] T056 Frontend build (`cd frontend && npm run build`) + PM2 restart + smoke-test Forecast → Results → Diagnostics flow
- [ ] T057 Commit all changes with scoped message + push to `origin/main`

---

## Dependencies

### Phase-level

- Phase 1 (Setup) can run in parallel with Phase 2 (Foundational).
- Phase 2 (Foundational) blocks Phases 4–6 directly and Phases 3, 7–12 indirectly.
- Phase 3 (US1 CV panel) is independent of Phase 2 and can ship alone as a partial MVP increment.
- Phase 4 (US2 real residuals) must complete before Phase 5 (US3 plots and tests) and Phase 6 (US4 coefficients).

### Task-level

- T010–T012 (forecaster residual extraction) → T013 (persistence) → T020 (diagnostics reads it)
- T014–T016 (coefficient extraction) → T030 (diagnostics renders)
- T044 (excel_exporter) → T045 + T046 (endpoints)
- T048 (report_exporter) → T050 (endpoint)

### Parallel opportunities

- Phase 1: T002, T003, T004, T005, T006, T007 all [P]
- Phase 2: T009, T011, T012, T015, T016 all [P]
- Phase 5: T024, T025, T026, T027 all [P]
- Phase 13: T052, T053, T054 all [P]

---

## MVP Scope

**Minimum viable increment**: Phases 1–4 (Setup, Foundational, US1 CV visibility, US2 real residuals).

These alone:
- Kill the fake-residual silent bug.
- Surface cross-validation the user paid compute to produce.
- Unblock all subsequent work.

US3 (more plots/tests), US4 (coefficient SE), US5 (stats panel), US6 (comparison UI) are additive and can ship incrementally afterwards. US7–US10 are polish — last to ship.

---

## Task Count Summary

| Phase | Tasks | Priority |
|-------|-------|----------|
| 1. Setup | 7 | P1 |
| 2. Foundational | 9 | P1 |
| 3. US1 CV panel | 3 | P1 |
| 4. US2 real residuals | 3 | P1 |
| 5. US3 plots + tests | 7 | P2 |
| 6. US4 coefficients | 3 | P2 |
| 7. US5 stats panel | 3 | P2 |
| 8. US6 model comparison | 3 | P2 |
| 9. US7 chart controls | 2 | P3 |
| 10. US8 table views | 3 | P3 |
| 11. US9 Excel export | 4 | P3 |
| 12. US10 diagnostics export | 4 | P3 |
| 13. Polish & benchmark | 6 | — |
| **Total** | **57** | |

Parallel-eligible: 18 tasks marked [P]. MVP (Phases 1–4): 22 tasks.
