# Phase 0 — Research & Decisions

**Feature**: Results & Diagnostics Parity
**Spec**: [spec.md](./spec.md)

## Overview

Six design questions surfaced during planning. Decisions are locked here so implementation can proceed without relitigation.

---

## Decision 1 — Residual storage format

**Decision**: Store residuals as a plain list of floats in `ForecastResultResponse.model_summary.residuals`, same field in Redis and Postgres. Truncate to the last 2000 values for safety (covers 5+ years of daily data; ~16 KB serialized).

**Rationale**: JSON is already the serialization format for model_summary; no new format to handle. 2000 values is enough for any statistical test we run (Ljung-Box uses 10-40 lags, Shapiro maxes at 5000, ACF maxes at N/2).

**Alternatives considered**:
- Binary blob (msgpack / base64-encoded numpy): marginal size gain, new decode path.
- External object store (S3): overkill for 16 KB per forecast.
- Don't truncate: acceptable but adds risk on 10-year hourly series.

---

## Decision 2 — Coefficient extraction shape

**Decision**: For ARIMA and ETS, extract `(estimate, std_error, z_stat, p_value, significant)` for every coefficient using statsmodels' `model.params`, `model.bse`, `model.tvalues`, `model.pvalues` accessors. Prophet returns `None` for coefficients (uses hyperparameter display instead).

```python
coefficients = []
for name, est in model.params.items():
    se = model.bse[name]
    z = model.tvalues[name]
    p = model.pvalues[name]
    coefficients.append({
        "name": str(name),
        "estimate": round(float(est), 6),
        "std_error": round(float(se), 6),
        "z_stat": round(float(z), 4),
        "p_value": round(float(p), 6),
        "significant": bool(p < 0.05),
    })
```

**Rationale**: All four statsmodels accessors are reliable for `ARIMA`, `SARIMAX`, and `ExponentialSmoothing` — confirmed in the library docs. Prophet's Bayesian fit doesn't produce classical frequentist p-values, so we render hyperparameters instead (matches old R app behaviour).

**Edge case**: statsmodels' `ExponentialSmoothing` result object has `.params` (smoothing params) but `.bse/.tvalues/.pvalues` can be missing when the optimizer returns bounds-constrained estimates. In that case we report estimate + "SE not available" rather than fabricating zeros.

---

## Decision 3 — PDF library choice

**Decision**: **HTML-only export for v1.** Defer PDF to a follow-up feature if user demand materialises.

**Rationale**:
- `weasyprint` on Windows pulls in GTK/Cairo native deps — not a clean pip install.
- Headless-chrome/puppeteer is heavy, needs a running Chromium.
- `reportlab` doesn't render HTML; requires rewriting the report layout.
- HTML is printable from any browser → users can "Save as PDF" from Chrome → 95% of the benefit at 0% of the dependency cost.

**If PDF later becomes required**: pick `weasyprint` and add it as a Linux-only dep in the Docker image; Windows dev env gets HTML only.

---

## Decision 4 — Excel export library

**Decision**: `openpyxl` via `pandas.ExcelWriter(engine='openpyxl')`.

**Rationale**: `openpyxl` is already in the dependency tree as a pandas transitive dependency — no new top-level dep. API is ergonomic for multi-sheet writes. Performance is fine for 50-entity batches.

**Alternatives**:
- `xlsxwriter`: marginally faster for formatting-heavy files but adds a dep.
- `pyexcelerate`: fastest but minimal feature set; can't do multiple sheets cleanly.

---

## Decision 5 — Historical-record detection

**Decision**: Use presence of `residuals` key (and non-null value) in `model_summary` as the discriminator.

```python
is_synthetic = not result.model_summary.get("residuals")
```

**Rationale**: Simple, works for both Redis and DB records, no new field to maintain. Any forecast written before this feature ships will lack the key; any forecast written after will have it (or explicitly null if fitting failed).

**Alternative**: new `diagnostics_source: "real" | "synthetic"` enum field. Rejected as over-engineering.

---

## Decision 6 — Old-record migration

**Decision**: No retroactive migration. Existing records stay as-is; Diagnostics page shows the "historical record" banner for them.

**Rationale**:
- Cannot re-compute residuals without refitting the model, which requires the original data — often gone from Redis after 2 hours.
- Refitting costs compute and is error-prone (column detection may differ from the original run).
- The user can simply re-run the forecast and get full diagnostics.

**User-facing copy** (in the banner):
> *"This forecast was created before residual diagnostics became available. Re-run the forecast to see complete residual analysis including ACF, Ljung-Box, Breusch-Pagan, and Shapiro-Wilk tests."*

---

## Testing Strategy

1. **Unit tests** (pytest) for `residual_tests.py`:
   - Ljung-Box on known-white-noise series → p > 0.05 (passes).
   - Ljung-Box on AR(1) simulated series with φ=0.8 → p < 0.01 (fails as expected).
   - Breusch-Pagan on homoscedastic series → p > 0.05.
   - Breusch-Pagan on series with expanding variance → p < 0.05.
   - Shapiro-Wilk on Gaussian noise → p > 0.05.
   - Shapiro-Wilk on exponential noise → p < 0.01.

2. **Integration test** of residual persistence:
   - Fit ARIMA, extract `model.resid`, run forecast through `forecast_service`, assert `result.model_summary["residuals"]` matches the original array within float precision.

3. **Manual walkthrough** ([quickstart.md](./quickstart.md)) covers all 10 user stories end-to-end.

4. **Benchmark** (scripts/benchmark_diagnostics.py, new in Phase 10): before this feature, 100% of Ljung-Box p-values come from synthetic data. After, verify they differ on a set of 20 adversarial datasets.
