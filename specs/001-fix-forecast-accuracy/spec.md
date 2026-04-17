# Feature Specification: Fix Forecast Accuracy

**Feature Branch**: `001-fix-forecast-accuracy`
**Created**: 2026-04-16
**Status**: Draft
**Input**: User description: "Fix forecast accuracy — auto-detect frequency, fix regressor detection, per-method min-data validation, ARIMA fallback chain, cross-validation"

## Background Context

Users are seeing "extremely bad" forecast accuracy in the new LUCENT app. A code review comparing the new Python/React implementation against the original R Shiny app surfaced thirteen issues, several of which are concrete bugs (not parity gaps) that directly corrupt forecast results. The most visible example: a user with 90 days of daily data selected "Weekly" in the Frequency dropdown, which caused the engine to build weekly-seasonal models on daily data and extend the forecast horizon by weeks instead of days.

This feature addresses accuracy at the root by auto-detecting data characteristics, guarding against silent misconfigurations, and measuring accuracy properly via cross-validation.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Forecast matches the data's natural frequency (Priority: P1)

As an analyst, when I upload daily time-series data and run a forecast, the model should automatically detect that my data is daily (not treat it as weekly or monthly), so my forecast horizon expressed in days produces a day-by-day forecast.

**Why this priority**: This is the single biggest cause of the "bad accuracy" complaint. A wrong frequency does not produce a slightly worse forecast — it produces a forecast for a completely different problem (e.g., 14 weeks instead of 14 days).

**Independent Test**: Upload a 90-row daily dataset, leave all frequency settings on "auto", run the forecast, confirm the output dates advance one day at a time for the requested horizon.

**Acceptance Scenarios**:

1. **Given** a dataset with 90 rows where each row is exactly one day apart, **When** the user runs a forecast without manually setting frequency, **Then** the system detects frequency as Daily and the forecast output has one prediction per day.
2. **Given** a dataset with weekly aggregated data (rows 7 days apart), **When** the user runs a forecast, **Then** the system detects Weekly frequency and the forecast output advances by 1 week per step.
3. **Given** the user manually picks "Weekly" but the data is daily, **When** they run the forecast, **Then** the system warns them of the mismatch before executing and offers to use detected frequency instead.

---

### User Story 2 — Only explicit regressors are used (Priority: P1)

As an analyst, I expect the model to use only the regressors I explicitly select. The system must not silently feed ID columns, row indices, or other irrelevant numeric columns into the model as "external regressors", because that destroys accuracy.

**Why this priority**: A Prophet model fed a numeric ID column as a regressor produces garbage output. This currently happens automatically with no user awareness.

**Independent Test**: Run a Prophet forecast on a dataset that has a numeric `Entity_ID` column without selecting any regressors. Confirm the forecast run does not include `Entity_ID` in the model's regressor list.

**Acceptance Scenarios**:

1. **Given** a dataset with numeric columns that are not marked as regressors, **When** the user runs Prophet, **Then** the forecast model uses zero regressors unless the user explicitly selected them in the UI.
2. **Given** the user explicitly selects two regressors from the regressor selector, **When** the forecast runs, **Then** the model uses exactly those two columns.

---

### User Story 3 — Poor forecasts are reported instead of silently produced (Priority: P1)

As an analyst, when my dataset is too small or inappropriate for the chosen method, the system should tell me up-front rather than producing a meaningless forecast.

**Why this priority**: A Prophet forecast on 12 rows is mathematically invalid — the model can't separate signal from noise. Users currently receive a forecast anyway and assume it is usable. Per-method minimum-data checks prevent this.

**Independent Test**: Try to forecast a 12-row dataset using Prophet. The system blocks the request with a clear message: "Prophet requires at least 15 observations."

**Acceptance Scenarios**:

1. **Given** a dataset with fewer than 15 rows, **When** the user runs Prophet, **Then** the system returns an error stating the minimum requirement and suggests alternatives.
2. **Given** a seasonal ARIMA run with seasonal period s=7 on 10 rows, **When** the user starts the forecast, **Then** the system blocks it because the requirement is `2 * s + 5 = 19` rows.
3. **Given** a dataset that meets the minimum for ETS but not for seasonal ARIMA, **When** the user picks ARIMA, **Then** the error message names ETS or Prophet as a viable alternative.

---

### User Story 4 — ARIMA recovers from fitting failures (Priority: P2)

As an analyst, if auto-ARIMA fails to find a good model, the system should try progressively simpler variants instead of failing outright and forcing me to retry.

**Why this priority**: Complex auto-ARIMA fits can fail for many reasons (convergence, collinearity, ill-conditioned seasonal search). The old R app falls back through simpler variants. The new app fails on the first attempt.

**Independent Test**: Trigger a dataset that's known to break the default auto-ARIMA search. Confirm the system falls back to a simpler ARIMA model and still produces a forecast rather than failing.

**Acceptance Scenarios**:

1. **Given** auto-ARIMA grid search fails, **When** the system attempts the fit, **Then** it retries with a simpler non-seasonal search before falling back to ARIMA(1,1,1).
2. **Given** the final fallback also fails, **When** the forecast returns, **Then** the error message explains that ARIMA is unsuitable for this data and suggests ETS or Prophet.

---

### User Story 5 — Out-of-sample accuracy can be measured via cross-validation (Priority: P2)

As an analyst, I want to know how well my model performs on unseen data, not just how closely it fits the training data. The cross-validation UI is already built but does not actually produce results.

**Why this priority**: The MAE/RMSE/MAPE numbers shown today are all **in-sample** metrics, which an overfit model can minimise trivially while still forecasting poorly. Without cross-validation, users can't compare ARIMA vs ETS vs Prophet meaningfully.

**Independent Test**: Enable cross-validation with 3 folds, run a forecast, and confirm the results panel shows per-fold metrics plus averages, and that these values differ from the in-sample metrics.

**Acceptance Scenarios**:

1. **Given** a dataset with enough rows and cross-validation enabled with 3 folds, **When** the forecast runs, **Then** the response includes per-fold MAE/RMSE/MAPE and the averaged metrics.
2. **Given** rolling-window CV is selected, **When** cross-validation runs, **Then** the training window slides forward by `floor(h / 2)` steps per fold.
3. **Given** expanding-window CV is selected, **When** cross-validation runs, **Then** each fold's training set begins at the dataset start and grows with each fold.

---

### User Story 6 — ARIMA seasonal parameters are properly searched (Priority: P2)

As an analyst, when the data has seasonality, the auto-ARIMA search should jointly optimise the seasonal and non-seasonal orders, not hardcode the seasonal order to (1,1,1).

**Why this priority**: The old R app's `auto.arima` does a joint search. The new app detects a seasonal period via ACF then forces `P=1, D=1, Q=1`, which overfits when the true seasonal order is (0,0,0) or (0,1,1).

**Independent Test**: Run ARIMA auto-detection on a synthetic series with a known `(1,0,1)(0,1,0,7)` structure. Confirm the detected order is at least in the neighbourhood, not always `(_,_,_)(1,1,1,7)`.

**Acceptance Scenarios**:

1. **Given** data with weekly seasonality but no seasonal differencing, **When** auto-ARIMA runs, **Then** the detected seasonal D is 0 rather than always 1.
2. **Given** data with strong seasonality, **When** auto-ARIMA runs, **Then** the grid search considers at least (0,0,0), (0,1,0), (1,0,0), and (1,1,1) for the seasonal component and picks the best by AIC.

---

### User Story 7 — Preventable misconfigurations are surfaced to the user (Priority: P3)

As an analyst, when I make a setting mistake that the system can detect (e.g., enabling yearly seasonality on 90 days of data), I want a warning before the forecast runs.

**Why this priority**: Not a bug, but a usability improvement. A Prophet model with yearly seasonality on 90 days of data invents a year-long cycle from thin air — visually obvious but not flagged.

**Independent Test**: Turn on yearly seasonality with a 90-day dataset and confirm a warning is surfaced in the UI before submission.

**Acceptance Scenarios**:

1. **Given** Prophet with yearly seasonality enabled and fewer than 730 days of data, **When** the user submits, **Then** a warning is shown that yearly seasonality may be inventing patterns.
2. **Given** the user acknowledges the warning, **When** they proceed, **Then** the forecast still runs.

---

### Edge Cases

- What happens when the data has irregular intervals (some days missing)? The system should resample to a regular grid before fitting, warn if gaps are significant (>10%).
- What happens when all values are identical (zero variance)? The system rejects the request with a clear message.
- What happens when the user selects a regressor that has future values missing? The system warns and uses the column mean for the forecast horizon, matching the old R app's behaviour.
- What happens when auto-frequency detection gives an ambiguous answer (mixed intervals)? The system falls back to the user's manual selection but warns.
- What happens when cross-validation has too few rows after splitting (e.g., horizon exceeds fold size)? The system reduces the fold count automatically and reports the adjustment.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST auto-detect the data's sampling frequency (daily / weekly / monthly / quarterly / yearly) from the median time delta between consecutive observations when the user has not explicitly chosen a frequency.
- **FR-002**: System MUST use the detected frequency to configure both the forecast model (seasonal lag candidates) and the future-date generation (so horizon units match the data).
- **FR-003**: System MUST NOT auto-detect any column as an external regressor. Regressors MUST be explicitly selected by the user in the UI and passed through to the model.
- **FR-004**: System MUST reject forecast requests that fail per-method minimum-observation requirements (Prophet >= 15; ARIMA non-seasonal >= 10; ARIMA seasonal >= 2*s + 5; ETS non-seasonal >= 10; ETS seasonal >= 2*freq + 5).
- **FR-005**: System MUST surface minimum-observation errors with the rule that was violated and at least one suggested alternative method that would work on the given data.
- **FR-006**: System MUST perform a cascading fallback when ARIMA fails: full auto-ARIMA -> simpler auto-ARIMA (non-seasonal, smaller grid) -> ARIMA(1,1,1). The user MUST see an error only if every attempt fails.
- **FR-007**: System MUST implement cross-validation (rolling-window and expanding-window) on the backend. The `CrossValidationRequest` schema MUST be honoured instead of ignored.
- **FR-008**: Cross-validation output MUST include per-fold MAE/RMSE/MAPE and the averaged metrics across folds, stored alongside the forecast record.
- **FR-009**: ARIMA auto-detection MUST jointly search non-seasonal and seasonal orders rather than hardcoding the seasonal order to (1,1,1).
- **FR-010**: ARIMA seasonal detection MUST use a stricter ACF threshold (>= 0.4) and confirm the period repeats across at least 2 cycles before declaring seasonality.
- **FR-011**: System MUST warn the user before executing when detectable misconfigurations exist: yearly seasonality with < 730 days of data; weekly seasonality with < 14 days of data; chosen frequency disagrees with detected frequency.
- **FR-012**: System MUST resample irregular time series to a regular grid (using the detected frequency) before fitting; gaps that require imputation MUST be noted in the forecast summary.
- **FR-013**: System MUST reject zero-variance series (all values identical) with a clear error message.

### Key Entities

- **ForecastRequest**: The user's submitted forecast configuration. New/changed fields include `frequency_auto_detect` (boolean, default true) and `regressor_columns` (explicit list, no implicit detection).
- **ForecastResult**: Response from the backend. New fields include `detected_frequency` (result of auto-detection), `warnings` (list of non-fatal issues surfaced during execution), and `cv_results` (populated when CV was enabled).
- **CrossValidationResult**: Per-fold metrics plus averages; persisted to `forecast_predictions.cv_results` JSON column.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Forecasts run on daily data without any manual frequency selection produce one prediction per day for a user-specified horizon in 100% of cases.
- **SC-002**: For datasets with numeric non-regressor columns (e.g., ID columns), Prophet runs use zero regressors unless the user explicitly selected some.
- **SC-003**: Forecast requests on datasets below the per-method minimum are blocked with a structured error in 100% of cases; no silent garbage forecasts are produced.
- **SC-004**: On a benchmark set of 20 synthetic series (mixed daily/weekly, with and without seasonality), out-of-sample MAPE (measured via cross-validation) is at least 30% lower than the current baseline.
- **SC-005**: Cross-validation, when enabled, populates `cv_results` with per-fold metrics in 100% of successful forecast runs; in-sample and out-of-sample metrics are reported side-by-side in the UI.
- **SC-006**: ARIMA fitting failure rate drops to under 5% on the benchmark set after the fallback chain is in place (vs measured baseline).
- **SC-007**: Users who misconfigure frequency (pick Weekly when data is daily) see a warning before the forecast runs in 100% of detectable cases.

## Assumptions

- Users have access to the forecast tab in the Next.js frontend and have successfully uploaded a dataset. Auth and data ingestion are out of scope.
- The data path from upload through preprocessing is already working correctly. This feature does not alter preprocessing or data loading.
- The existing Redis + Postgres dual-storage pattern for forecast results remains unchanged.
- Changes are backward-compatible at the API boundary where possible; fields that no longer need to be submitted (like manual frequency) remain in the schema but default to auto-detect.
- Prophet's CmdStan dependency is assumed installed. This feature does not attempt to work around missing CmdStan.
- The existing benchmark dataset (or a reasonable synthetic substitute) is available for measuring SC-004/SC-006.
