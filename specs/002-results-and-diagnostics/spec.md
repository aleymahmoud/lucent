# Feature Specification: Results & Diagnostics Parity

**Feature Branch**: `002-results-and-diagnostics`
**Created**: 2026-04-17
**Status**: Draft
**Input**: User description: "Results and Diagnostics parity with old R app — show CV results, real residuals, statistical tests, full export, model comparison UI"

## Background Context

After completing spec 001 (forecast accuracy fixes), a comparison of the Results and Diagnostics pages against the old R Shiny app surfaced 17 parity gaps. The single most damaging finding: the Diagnostics tab's residual analysis is statistically meaningless because the backend doesn't persist real residuals — it reconstructs them on the fly with `np.random.normal(seed=42)`. Every test downstream (ACF, Ljung-Box, Jarque-Bera) operates on that synthetic data, not the model's actual errors.

The second-highest-impact finding: cross-validation results from spec 001 are returned by the backend but never shown in the UI, so that work is invisible to users.

This feature closes the parity gap on both pages, restoring the old R app's statistical rigor and export options while keeping the new app's cleaner UX.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Cross-validation results are visible in the UI (Priority: P1)

As an analyst, after I run a forecast with cross-validation enabled, I want to see the per-fold and averaged out-of-sample metrics on the Results page alongside the in-sample metrics, so I can tell whether the model actually generalises.

**Why this priority**: CV results are already computed and returned by the backend (spec 001 delivered this). Not showing them means users can't tell whether their forecast is overfitting. This alone restores the ability to pick the right model for production.

**Independent Test**: Run a forecast with `cross_validation.enabled = true`, open Results, confirm a "Cross-Validation" section renders with per-fold rows and averaged metrics.

**Acceptance Scenarios**:

1. **Given** a completed forecast with `cv_results` populated, **When** the user opens the Results page, **Then** an "Out-of-Sample Accuracy" panel shows the fold count, the method (rolling/expanding), one row per fold (MAE/RMSE/MAPE), and an "Average" row.
2. **Given** the forecast has `cv_results = null`, **When** the user opens Results, **Then** the CV panel is hidden (not rendered, no empty placeholder).
3. **Given** both in-sample metrics and CV averages exist, **When** the user views the metric cards, **Then** both values are shown side-by-side so the gap between training fit and out-of-sample accuracy is obvious.

---

### User Story 2 — Residual analysis uses real residuals (Priority: P1)

As an analyst, when I view residual diagnostics (ACF plot, Ljung-Box test, Jarque-Bera test), the numbers must come from the model's actual errors, not a synthetic normal distribution derived from mean+std.

**Why this priority**: The current implementation runs statistical tests on `np.random.normal(mean, std, size=n, seed=42)`. These tests are by definition designed to detect departures from normality / independence — feeding them normally-distributed synthetic data produces hardcoded "passes" regardless of whether the real residuals are problematic. Users are being told their model is fine when it may not be.

**Independent Test**: Fit an ARIMA model on a dataset with known autocorrelation in residuals. Confirm Ljung-Box p-value correctly rejects the null (indicating autocorrelation) — with the current stub, it would always pass.

**Acceptance Scenarios**:

1. **Given** a forecast has completed, **When** the Diagnostics page loads, **Then** the residuals array used for ACF/PACF/Ljung-Box/Jarque-Bera is the actual `model.resid` from fitting, not a reconstructed synthetic series.
2. **Given** a dataset with strongly autocorrelated residuals, **When** Ljung-Box runs, **Then** the p-value is < 0.05 and the UI badge says "Autocorrelation detected".
3. **Given** the forecast record was written before this feature ships (no residuals field), **When** the Diagnostics page loads, **Then** the page renders with a banner "Residual detail unavailable for this historical record — re-run the forecast for full diagnostics" instead of silently fabricating data.

---

### User Story 3 — Missing residual plots and tests are available (Priority: P2)

As an analyst, I want the same set of residual visualisations and tests the old R app offered: residual time series with ±σ bands, histogram with normal + KDE overlay, QQ plot, ACF, plus Breusch-Pagan (heteroscedasticity) and Shapiro-Wilk (normality) tests.

**Why this priority**: Scatter of residuals is not enough to judge model adequacy. Old R app had four plot types and three formal tests. Restoring them is straightforward given real residuals (US2).

**Independent Test**: Navigate to Diagnostics → Residuals tab, switch between Time Series / Histogram / QQ / ACF, confirm each renders with real data. Check the "Tests" box for Ljung-Box + Breusch-Pagan + Shapiro-Wilk p-values.

**Acceptance Scenarios**:

1. **Given** a completed forecast, **When** the user opens the Residuals tab, **Then** a plot-type selector offers Time Series, Histogram, QQ, and ACF options.
2. **Given** the Time Series plot is selected, **When** it renders, **Then** residuals appear as points with a line overlay and reference lines at 0, ±σ, ±2σ.
3. **Given** the Tests box is shown, **When** it renders, **Then** it lists Ljung-Box (autocorrelation), Breusch-Pagan (heteroscedasticity), and Shapiro-Wilk (normality) with p-values and plain-English interpretations.

---

### User Story 4 — Model parameters show standard errors and significance (Priority: P2)

As an analyst viewing the Model tab, I want to see each coefficient's estimate, standard error, z-statistic, and p-value so I can tell which parameters are statistically meaningful.

**Why this priority**: Without SE + p-values, I can't tell whether a non-zero coefficient is real or noise. Old R app exposed all four columns.

**Independent Test**: Fit an ARIMA with known-significant and known-insignificant coefficients. Confirm the UI shows both the estimate and p-value, and flags insignificant coefficients.

**Acceptance Scenarios**:

1. **Given** a fitted ARIMA or ETS model, **When** the Diagnostics Model tab renders, **Then** each coefficient shows estimate, std. error, z-stat, and p-value columns.
2. **Given** a coefficient has p-value > 0.05, **When** it renders, **Then** a warning badge ("Not significant") appears next to its row.
3. **Given** Prophet is the method, **When** the Model tab renders, **Then** it shows the configured hyperparameters (changepoint prior, seasonality prior, growth type, seasonality toggles) since Prophet doesn't expose traditional coefficients.

---

### User Story 5 — Forecast Statistics panel on Results page (Priority: P2)

As an analyst, I want a Forecast Statistics panel that shows summary stats of the forecasted values (mean / median / quartiles / min / max / average interval width), so I can eyeball reasonability.

**Why this priority**: Old R app had this; it's a quick sanity check — if the forecast mean is negative for a sales series, something is wrong.

**Independent Test**: Run any forecast, confirm a "Forecast Statistics" panel renders on the Results page with six numbers.

**Acceptance Scenarios**:

1. **Given** a completed forecast, **When** the user opens Results, **Then** a Forecast Statistics panel shows mean, median, min, max, IQR, and average interval width of the forecasted values.
2. **Given** the data is currency or units-based, **When** numbers render, **Then** they are formatted consistently (2 decimal places, thousands separators for large values).

---

### User Story 6 — Model comparison UI (Priority: P2)

As an analyst, I want to compare ARIMA vs ETS vs Prophet on my dataset side-by-side. The backend already has `POST /diagnostics/compare`; this feature wires a UI to it.

**Why this priority**: Without the UI, users have no way to invoke this endpoint. Old R app had a "Run Comparison" button in Diagnostics.

**Independent Test**: On the Diagnostics page, click "Compare Models", pick at least two methods, confirm a comparison table renders with the best model highlighted.

**Acceptance Scenarios**:

1. **Given** the Diagnostics page is open, **When** the user clicks "Compare Models", **Then** a panel appears with checkboxes for ARIMA, ETS, Prophet.
2. **Given** two or more methods are selected, **When** the user clicks "Run Comparison", **Then** the backend runs each method and returns composite scores and per-metric values.
3. **Given** the comparison completes, **When** results render, **Then** a table shows Model / MAE / RMSE / MAPE / Composite Score, with the best row highlighted.

---

### User Story 7 — Chart controls on the forecast plot (Priority: P3)

As an analyst viewing the Results chart, I want to switch between Line / Line with Points / Area, toggle prediction intervals, and use a range slider for long histories.

**Why this priority**: Polish — old R app had these; not critical but noticeable to users familiar with the old tool.

**Independent Test**: Open Results, switch plot types, hide prediction intervals, zoom with the range slider. Confirm each works.

**Acceptance Scenarios**:

1. **Given** the forecast chart is rendered, **When** the user selects "Area" in a plot-type selector, **Then** the historical line becomes a filled area.
2. **Given** a "Show intervals" checkbox exists, **When** it's unchecked, **Then** the prediction band disappears and the upper/lower lines hide.
3. **Given** the chart has more than 90 days of history, **When** it renders, **Then** a range slider appears below the X-axis.

---

### User Story 8 — Results table has multiple views (Priority: P3)

As an analyst, I want to switch the Results table between "Forecast Only" (default), "Historical + Forecast" (two columns), and "Full Data" (one value column, Type col identifies row type).

**Why this priority**: Matches old R app behaviour; useful for exporting, less critical than CV visibility.

**Independent Test**: On Results, switch the table view, confirm rows/columns change per mode.

**Acceptance Scenarios**:

1. **Given** the Results Data tab is open, **When** the user picks "Historical + Forecast", **Then** the table gains a "Historical" column and the rows expand to include pre-forecast dates.
2. **Given** "Full Data" is selected, **When** the table renders, **Then** each row has a "Type" column (Historical / Forecast) and a single "Value" column.

---

### User Story 9 — Multi-format export (Priority: P3)

As an analyst, I want to download forecasts as Excel (with multiple sheets: forecast, metrics, model summary) and in a "Download All Entities" flavor that puts one sheet per entity.

**Why this priority**: Old R app had these. Many users live in Excel.

**Independent Test**: On Results, click "Export → Excel", open the file, confirm it has at least three sheets.

**Acceptance Scenarios**:

1. **Given** a completed single-entity forecast, **When** the user clicks "Download Excel", **Then** the downloaded .xlsx has sheets: "Forecast", "Metrics", "Model Summary" (and "Cross-Validation" if applicable).
2. **Given** a completed batch forecast, **When** the user clicks "Download All Entities (Excel)", **Then** the .xlsx has one sheet per entity plus a "Summary" sheet and a combined "All Data" sheet.

---

### User Story 10 — Diagnostics export (Priority: P3)

As an analyst, I want to export a Diagnostics report as PDF or HTML for sharing with stakeholders.

**Why this priority**: Old R app had the selector. Useful for hand-offs.

**Independent Test**: On Diagnostics, click "Export Report", pick PDF, download, verify content (residual plots + tests + quality scores).

**Acceptance Scenarios**:

1. **Given** a complete diagnostics view, **When** the user clicks "Export Report → HTML", **Then** the downloaded HTML has all visible charts + tests + quality scores embedded as images or SVG.
2. **Given** the user picks PDF, **When** the export runs, **Then** the response is a PDF file with the same content as the HTML version.

---

### Edge Cases

- Forecasts written before residuals are persisted: show a one-line banner explaining the limitation; don't fabricate data.
- Very long residual arrays (>5000 points) for Shapiro-Wilk: skip Shapiro with a note — scipy's implementation rejects > 5000.
- Model comparison when Prophet is missing CmdStan: gracefully skip Prophet, compare the other two.
- Excel export of 50-entity batches: one sheet per entity hits Excel's 31-character sheet name limit — truncate + deduplicate with numeric suffixes.
- QQ plot when residuals have < 20 points: still render but warn that the plot is noisy.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST persist the full residuals array for every forecast (in-memory Redis result + `forecast_predictions.model_summary` JSON column under a new `residuals` key).
- **FR-002**: Diagnostics service MUST use the persisted residuals array as-is; if absent (historical records), MUST return an error flag instead of synthesising data.
- **FR-003**: Results page MUST display the cross-validation results when `cv_results` is populated: fold count, method, per-fold MAE/RMSE/MAPE rows, and average metrics.
- **FR-004**: Results page MUST display a Forecast Statistics panel with mean, median, quartiles, min, max, and average prediction-interval width of the forecasted values.
- **FR-005**: Diagnostics Residuals tab MUST offer four plot types (Time Series with ±σ bands, Histogram with normal + KDE overlay, QQ, ACF) selectable via a dropdown or tabs.
- **FR-006**: Diagnostics Residuals tab MUST compute and display Ljung-Box, Breusch-Pagan, and Shapiro-Wilk tests (when data size permits) with p-values and plain-English interpretations.
- **FR-007**: Diagnostics Model tab MUST show estimate, standard error, z-statistic, and p-value for each coefficient (ARIMA/ETS only; Prophet shows configured hyperparameters).
- **FR-008**: Diagnostics page MUST provide a "Compare Models" panel that calls the existing `POST /diagnostics/compare` endpoint and renders the response as a table.
- **FR-009**: Results page MUST offer Excel export (single-entity multi-sheet and all-entities one-sheet-per-entity) in addition to the existing CSV + JSON.
- **FR-010**: Diagnostics page MUST offer PDF and HTML report export.
- **FR-011**: Results forecast chart MUST offer plot-type selector (Line / Line with Points / Area), a show-intervals toggle, and an auto-enabled range slider for histories longer than 90 points.
- **FR-012**: Results table MUST offer three view modes: "Forecast Only" (default), "Historical + Forecast", "Full Data".
- **FR-013**: Seasonality tab MUST render per-component decomposition for Prophet (yearly + weekly) and seasonal subseries for ARIMA/ETS when seasonality is detected.

### Key Entities

- **ForecastResultResponse**: gains `residuals: List[float] | None` (populated when fitted, null for historical records).
- **DiagnosticsResidualsResponse**: new field `is_synthetic: bool` — when True, clients know to display the historical-record banner.
- **ModelCoefficient**: new shape `{ name: str, estimate: float, std_error: float, z_stat: float, p_value: float, significant: bool }` — replaces the current raw `Dict[str, float]` for coefficients.
- **ComparisonResult**: reused from existing `/diagnostics/compare` response; requires frontend rendering only.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of forecasts completed after this feature ships have a non-null `residuals` array persisted to the Redis cache and to `forecast_predictions.model_summary`.
- **SC-002**: Ljung-Box p-values produced by the Diagnostics page differ from the current synthetic-residuals output on at least 90% of a benchmark set of 20 datasets with injected autocorrelation.
- **SC-003**: On the Results page, cross-validation metrics are visible for 100% of forecasts run with `cross_validation.enabled = true`.
- **SC-004**: On the Diagnostics page, at least three residual plot types (Time Series, Histogram, ACF) and three tests (Ljung-Box, Breusch-Pagan, Shapiro-Wilk) render for every completed forecast with >= 20 observations.
- **SC-005**: Excel export of a single-entity forecast produces a .xlsx file with >= 3 sheets in under 2 seconds.
- **SC-006**: Model comparison UI completes a 3-method comparison on a 90-day dataset in under 60 seconds.
- **SC-007**: Coefficient tables show p-values for 100% of ARIMA/ETS forecasts (Prophet exempt — no coefficient table).

## Assumptions

- The residuals array, even for 2000-point series, is acceptable storage overhead (~16 KB per forecast; Redis 1h TTL limits cumulative size; Postgres JSON column can hold it).
- `statsmodels` Ljung-Box (`acorr_ljungbox`), Breusch-Pagan (`het_breuschpagan`), and Shapiro-Wilk (`scipy.stats.shapiro`) are already available via existing backend deps (statsmodels, scipy).
- PDF export can use `weasyprint` or a lightweight HTML-to-PDF path; if neither is installed, HTML export alone is acceptable for the first increment.
- Excel export will use `openpyxl` (already a pandas dependency).
- The old R app's "parameter stability rolling plot" is out of scope for the initial increment — deferred.
- Frontend Plotly chart library is already the one used by the existing chart; no new charting dep is introduced.
