# Quickstart — Manual Verification

**Feature**: Fix Forecast Accuracy
**Plan**: [plan.md](./plan.md)

## Purpose

Walk through each user story end-to-end after implementation is complete, confirming the acceptance scenarios from [spec.md](./spec.md) hold.

## Prerequisites

1. Backend + frontend running (`pm2 restart lucent-backend lucent-frontend`)
2. Logged in as an analyst with access to at least one tenant
3. Test datasets available — generate with `python scripts/generate_test_datasets.py` (to be created during Phase 2)

---

## Walkthrough 1 — Daily data, auto-detect (US1)

**Dataset**: `daily_90.csv` — 90 rows, one per day, single entity, clear weekly pattern.

Steps:
1. Navigate to the Forecast page, select `daily_90.csv`, pick the only entity.
2. In Frequency, leave "Auto-detect" checked (default).
3. Pick method = Prophet, horizon = 14, keep weekly seasonality on, turn off yearly/daily.
4. Click Run.

**Expected**:
- Right after selecting the entity, the UI shows "Detected: Daily" next to the frequency dropdown.
- Forecast completes without error.
- Output dates advance by 1 day per step, starting the day after the last training date.
- No warning about frequency mismatch.
- `detected_frequency = "D"` in the result payload.

---

## Walkthrough 2 — Weekly data, auto-detect (US1)

**Dataset**: `weekly_104.csv` — 104 rows, one per week (Monday).

Steps:
1. Select `weekly_104.csv`, pick entity.
2. Auto-detect on.
3. Method = ARIMA, horizon = 4.
4. Run.

**Expected**:
- Detected = Weekly.
- Output dates advance by 7 days per step.
- ARIMA's reported seasonal period = 52 (yearly-in-weekly-data) if joint search found it, else `None`.

---

## Walkthrough 3 — Frequency mismatch warning (US1)

**Dataset**: `daily_90.csv`.

Steps:
1. Select daily_90.
2. Uncheck auto-detect; manually pick Weekly.
3. Run.

**Expected**:
- Before the run executes, a warning appears: "Selected frequency Weekly does not match detected Daily. Using detected (D)."
- Or, depending on final UI decision: a blocking confirmation dialog ("Continue with Weekly?" / "Use Daily instead").
- Either way, the forecast does not silently run with wrong frequency.

---

## Walkthrough 4 — No implicit regressors (US2)

**Dataset**: `daily_with_ids.csv` — daily data with a numeric `product_id` column.

Steps:
1. Select dataset, pick method = Prophet.
2. Do **not** select any regressors in the Regressor Selector.
3. Run.

**Expected**:
- Model summary in the response shows `regressors_used: []` (empty list).
- Server logs do not mention `product_id` as a regressor.
- Forecast quality is comparable to running the same data without the `product_id` column (sanity check).

Steps (continued — positive case):
4. Reset. Explicitly check the "promo" regressor column.
5. Run.

**Expected**:
- `regressors_used: ["promo"]` in the response.
- `product_id` still not present.

---

## Walkthrough 5 — Minimum-data rejection (US3)

**Dataset**: `tiny_12.csv` — 12 rows, daily.

Steps:
1. Select dataset, pick Prophet.
2. Run.

**Expected**:
- HTTP 400 with body `{ "detail": "Prophet requires >=15 observations, dataset has 12. Try ETS or ARIMA (non-seasonal) instead." }`.
- UI shows the error as a toast.

Steps (continued):
3. Change method to ETS, leave seasonality off.
4. Run.

**Expected**:
- Forecast runs successfully.

---

## Walkthrough 6 — ARIMA fallback (US4)

**Dataset**: `problematic.csv` — a dataset known to break the default auto-ARIMA grid search (e.g., near-constant with a single outlier, or perfect linear trend with no noise).

Steps:
1. Select dataset, pick ARIMA with auto-detect on.
2. Run.

**Expected**:
- Server logs show the fallback cascade: "auto-ARIMA full grid failed -> retrying simpler -> using ARIMA(1,1,1)".
- Forecast returns successfully with the fallback model.
- `model_summary.parameters.fallback_level` in the response indicates which level succeeded.

---

## Walkthrough 7 — Cross-validation (US5)

**Dataset**: `daily_90.csv`.

Steps:
1. Select dataset, method = Prophet, horizon = 14.
2. Enable Cross-Validation: 3 folds, rolling window, initial train 70%.
3. Run.

**Expected**:
- Forecast completes.
- Response includes `cv_results` with `folds=3`, `method="rolling"`, `metrics_per_fold` array of 3 entries, and `average_metrics`.
- The UI shows the CV metrics alongside the in-sample metrics.
- CV average MAPE is typically higher than in-sample MAPE (confirming they are different measurements).

---

## Walkthrough 8 — Yearly-seasonality warning (US7)

**Dataset**: `daily_90.csv`.

Steps:
1. Select dataset, method = Prophet.
2. Enable Yearly seasonality.
3. Submit.

**Expected**:
- Before fitting, the response includes a warning: "Yearly seasonality enabled on only 90 days of data (recommended >=730). Consider disabling."
- Forecast still runs (warning is advisory, not blocking).

---

## Walkthrough 9 — Irregular intervals (edge case)

**Dataset**: `irregular.csv` — daily data with 15% of days missing.

Steps:
1. Select dataset, auto-detect, run Prophet.

**Expected**:
- Detected = Daily.
- Warning: "Dataset has irregular intervals (15% of gaps deviate >50% from median). Data will be resampled to daily grid with missing dates imputed."
- Forecast produces a continuous daily output.

---

## Walkthrough 10 — Zero variance (edge case)

**Dataset**: `flat.csv` — 30 rows, value always 100.

Steps:
1. Run any method.

**Expected**:
- HTTP 400: `{ "detail": "All values are identical; forecasting requires variation." }`

---

## Benchmarking (SC-004, SC-006)

After all functional walkthroughs pass, run:

```bash
cd backend && python scripts/benchmark_forecasts.py
```

The script produces a comparison table across 20 synthetic series. Expectations:

- Average out-of-sample MAPE at least 30% lower than a snapshot of current values (recorded before the fix is deployed).
- ARIMA fitting failure rate < 5% (from the fallback chain).

Commit the baseline values in `specs/001-fix-forecast-accuracy/baseline.json` so the improvement is measurable.
