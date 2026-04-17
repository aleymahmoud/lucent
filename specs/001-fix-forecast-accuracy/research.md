# Phase 0 — Research & Decisions

**Feature**: Fix Forecast Accuracy
**Spec**: [spec.md](./spec.md)

## Overview

Six design questions surfaced during planning. This document records the decision for each, the rationale, and the alternatives considered so Phase 1/2 contributors don't relitigate them.

---

## Decision 1 — Frequency detection algorithm

**Decision**: Median time delta, with explicit month/quarter/year bucketing matching the old R app.

```python
def detect_frequency(dates: pd.DatetimeIndex) -> tuple[str, int]:
    diffs_days = dates.to_series().diff().dropna().dt.total_seconds() / 86400
    median = diffs_days.median()
    if 0.5 <= median <= 1.5:       return "D", 7       # daily, weekly seasonal period
    if 6   <= median <= 9:          return "W", 52      # weekly, yearly seasonal period
    if 28  <= median <= 31:         return "M", 12      # monthly, yearly seasonal period
    if 85  <= median <= 94:         return "Q", 4       # quarterly, yearly seasonal period
    if 360 <= median <= 370:        return "Y", 1       # yearly
    return "D", 7   # default fallback
```

**Rationale**: Matches the old R app's `detect_frequency()` (lines 3549-3597) exactly. Median is more robust than mode against a few irregular gaps. Explicit buckets handle 28-31 day variation in months.

**Alternatives considered**:
- Mode — fails when data has frequent 1-2 day gaps even within a "daily" series
- Pandas `pd.infer_freq()` — too strict; returns None on any irregularity
- Hybrid (mode + median) — unnecessary complexity for no measurable gain

---

## Decision 2 — ARIMA joint seasonal search bounds

**Decision**: Match the old R `auto.arima` exactly — test all (P,D,Q) combinations with `P in {0,1,2}, D in {0,1}, Q in {0,1,2}` = 18 combos, plus the existing (p,d,q) non-seasonal grid of 4×3×4 = 48. Total: 48 × 18 = 864 fits in the worst case.

**Rationale**: The old R app does this search and produces good forecasts. 864 fits is acceptable given typical datasets of < 1000 rows. Early termination when AIC stops improving can trim it further.

**Alternatives considered**:
- Smaller seasonal grid (max.P=max.Q=1, max.D=1 → 8 combos × 48 = 384): cheaper but risks missing the right model for strongly-seasonal series
- `pmdarima.auto_arima` library: adds a dependency; our grid search is already working for non-seasonal and extending it is straightforward
- Stepwise search (as R's default): more complex to implement correctly; not worth it unless the full grid proves too slow in practice

**Performance guard**: If a full search takes > 30 seconds for a single entity, fall back automatically to the smaller 384-combo grid. Log the decision.

---

## Decision 3 — Cross-validation fold-size rule

**Decision**: Match old R: `h_cv = min(12, floor(n * 0.15))` for auto mode; allow user override via the existing `CrossValidationRequest.initial_train_size` field (0.5-0.9, default 0.7).

**Rationale**: The rule is familiar, battle-tested, and user-configurable when needed. Exposing two knobs (fold count, initial train size) gives advanced users control without cluttering the default UX.

**Alternatives considered**:
- Fixed horizon (e.g., 7 days) — too rigid for weekly/monthly data
- User-configurable only — loses a sensible default that works for most cases
- Percentage-only (e.g., 10% of data per fold) — fine-grained but harder to reason about

---

## Decision 4 — Rolling vs expanding window semantics

**Decision**:
- **Rolling**: `train = data[start + k·step : start + k·step + initial_train]`, `test = data[...]` — training window slides forward by `step` per fold.
- **Expanding**: `train = data[0 : initial_train + k·step]`, `test = data[...]` — training set begins at index 0 and grows.

```python
step = max(1, h_cv // 2)
for k in range(folds):
    train_start = k * step if mode == "rolling" else 0
    train_end   = train_start + initial_train + (k * step if mode == "expanding" else 0)
    test_end    = train_end + h_cv
    train = series[train_start:train_end]
    test  = series[train_end:test_end]
```

**Rationale**: Standard time-series CV formulation. Matches Hyndman's description in "Forecasting: Principles and Practice", which the old R app follows implicitly.

**Alternatives considered**:
- Block-CV (non-contiguous blocks) — breaks temporal order; inappropriate for forecasting
- Leave-one-out — too many refits; prohibitively slow for ARIMA/Prophet

---

## Decision 5 — Minimum-data alternative recommendation

**Decision**: When a method fails its min-data check, suggest the cheapest method that would work:

| Data length | Suggested method |
|-------------|------------------|
| n < 10 | None — reject entirely, no forecasting viable |
| 10 ≤ n < 15 | ARIMA non-seasonal or ETS non-seasonal |
| 15 ≤ n < 2·s + 5 (seasonal fails) | Prophet, or ETS/ARIMA without seasonality |
| n ≥ 2·s + 5 | All three methods |

The error message pattern:

> "Prophet requires ≥15 observations, dataset has 12. Try **ETS** or **ARIMA (non-seasonal)** instead, which work with as few as 10 observations."

**Rationale**: Users who hit the limit want an actionable next step, not a dead end.

---

## Decision 6 — Warning delivery mechanism

**Decision**: Return warnings in the POST /forecast/run response body, plus add a dedicated `POST /forecast/detect-frequency` endpoint for the UI to pre-populate the "Detected: Daily" hint next to the frequency dropdown before the user hits Run.

**Rationale**:
- Warnings in /run response are always delivered (no dependence on a pre-flight call completing first).
- /detect-frequency is lightweight (no model fitting) and lets the UI provide immediate feedback.
- Avoids a new /forecast/validate endpoint whose blocking errors would duplicate /run's validation logic.

**Alternatives considered**:
- Only /run returns warnings — UI can't show anything until the user clicks Run, which is worse UX.
- Separate /forecast/validate + /run — two endpoints doing half the same work; more surface area to keep in sync.

---

## Data Characteristic Checks (Summary)

Derived from the six decisions, these become the master list of checks the backend performs on every request:

1. **Frequency detection** (always, if `frequency_auto_detect=true`) — output goes into response as `detected_frequency`
2. **Frequency mismatch warning** — if `request.frequency` differs from detected, add warning
3. **Minimum data check** — method-specific; blocks execution if failed
4. **Zero-variance check** — blocks execution with clear message
5. **Yearly seasonality viability** (Prophet only) — warn if enabled and n < 730
6. **Weekly seasonality viability** (Prophet only) — warn if enabled and n < 14
7. **Regressor whitelist** — only request.regressor_columns are used; no auto-detection
8. **Irregular interval check** — warn if > 10% of intervals deviate from median by more than 50%

---

## Testing Strategy

Since the project has minimal automated tests today, verification relies on:

1. **Synthetic benchmark set**: A small Python script (`scripts/benchmark_forecasts.py`) that generates 20 synthetic series with known properties (daily+weekly seasonal, monthly+yearly seasonal, pure random walk, trending, etc.) and runs both old and new forecast paths for MAPE comparison.
2. **Quickstart walkthrough** (`quickstart.md`): Manual step-by-step verification for each user story against a real upload via the UI.
3. **Unit tests** (new): pytest coverage for the CV engine (edge cases: too few rows, fold horizon > remaining data) and the frequency detector (all buckets + edge overlaps).

No test-driven-development requirement is imposed given the small scale and lack of existing test infrastructure, but new shared utilities (CV engine, frequency detector) MUST have pytest coverage.
