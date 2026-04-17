# Phase 1 — API Contracts

**Feature**: Fix Forecast Accuracy
**Plan**: [../plan.md](../plan.md)

## Endpoint Summary

| Method | Path | Status | Purpose |
|--------|------|--------|---------|
| POST | `/api/v1/forecast/run` | MODIFIED | Run forecast; now accepts auto-detect flag, returns warnings + detected_frequency |
| POST | `/api/v1/forecast/batch` | MODIFIED | Same changes as /run, applied per entity |
| POST | `/api/v1/forecast/detect-frequency` | **NEW** | Pre-flight frequency detection for UI hinting |
| POST | `/api/v1/forecast/auto-params/{method}` | UNCHANGED | Method-specific parameter recommendation (already works) |
| GET | `/api/v1/forecast/status/{forecast_id}` | UNCHANGED | Poll for status (now also returns warnings once complete) |
| GET | `/api/v1/forecast/batch/{batch_id}` | UNCHANGED | Poll batch status |

---

## Modified: `POST /api/v1/forecast/run`

### Request (changes marked)

```jsonc
{
  "dataset_id": "uuid",
  "entity_id": "string",
  "method": "arima" | "ets" | "prophet",
  "horizon": 14,
  "frequency": "D",                              // still accepted
  "frequency_auto_detect": true,                 // NEW (default true)
  "confidence_level": 0.95,
  "regressor_columns": ["promo", "weather"],     // explicit list only, no auto-detect
  "cross_validation": {                          // now honored (was ignored)
    "enabled": true,
    "folds": 3,
    "method": "rolling",
    "initial_train_size": 0.7
  },
  "arima_settings": {...},
  "ets_settings": {...},
  "prophet_settings": {...}
}
```

### Response (changes marked)

```jsonc
{
  "id": "uuid",
  "status": "completed",
  "method": "prophet",
  "detected_frequency": "D",                     // NEW
  "detected_seasonal_period": 7,                 // NEW
  "warnings": [                                  // NEW
    "You selected Weekly but data appears to be Daily — using Daily."
  ],
  "predictions": [...],
  "metrics": { "mae": 12.3, "rmse": 18.5, "mape": 9.8 },
  "model_summary": {...},
  "cv_results": {                                // NOW POPULATED when enabled
    "folds": 3,
    "method": "rolling",
    "metrics_per_fold": [
      {"mae": 15.2, "rmse": 21.4, "mape": 11.1},
      {"mae": 13.8, "rmse": 19.0, "mape": 10.3},
      {"mae": 14.5, "rmse": 20.1, "mape": 10.7}
    ],
    "average_metrics": {"mae": 14.5, "rmse": 20.2, "mape": 10.7}
  }
}
```

### Error Responses

| HTTP | Code | Trigger | Body |
|------|------|---------|------|
| 400 | `INSUFFICIENT_DATA` | Dataset fails per-method min-data check | `{ "detail": "Prophet requires >=15 observations, dataset has 12. Try ETS or ARIMA (non-seasonal) instead." }` |
| 400 | `ZERO_VARIANCE` | All values identical | `{ "detail": "All values are identical; forecasting requires variation." }` |
| 400 | `INVALID_COLUMN` | Explicit regressor column doesn't exist | `{ "detail": "Regressor column 'promo' not found in dataset." }` |

---

## New: `POST /api/v1/forecast/detect-frequency`

Lightweight pre-flight that detects frequency and surfaces warnings without fitting a model. Used by the UI to render "Detected: Daily" and display warnings before the user submits.

### Request

```jsonc
{
  "dataset_id": "uuid",
  "entity_id": "string",            // optional — if omitted, detect on full dataset
  "entity_column": "Product_ID",    // optional — for entity filtering
  "date_column": "Date"             // optional — backend auto-detects if omitted
}
```

### Response

```jsonc
{
  "detected_frequency": "D",
  "detected_seasonal_period": 7,
  "median_interval_days": 1.0,
  "observation_count": 90,
  "irregular_intervals_pct": 0.0,
  "warnings": [
    "Dataset has 90 observations. Yearly seasonality (requires >=730) will be disabled if enabled."
  ]
}
```

### Performance

Must return in < 500ms for typical datasets (no model fitting, no heavy computation — only pandas index arithmetic).

### Error Responses

| HTTP | Code | Trigger | Body |
|------|------|---------|------|
| 400 | `NO_DATE_COLUMN` | Date column not detected and not specified | `{ "detail": "Could not detect date column. Please specify date_column." }` |
| 404 | — | Dataset not found | `{ "detail": "Dataset not found or expired" }` |

---

## Modified: `POST /api/v1/forecast/batch`

Same request/response additions as `/run`, applied to each entity independently. Per-entity warnings are collected into the batch status response under `results[entity_id].warnings`.

---

## Modified: `GET /api/v1/forecast/status/{forecast_id}`

Response shape unchanged structurally but now includes the new fields (`detected_frequency`, `warnings`, `cv_results`) once the forecast completes.

---

## Backward Compatibility

- Existing clients that don't send `frequency_auto_detect` get `True` as the default — behaviour changes from "use my `frequency` value" to "auto-detect and use that". **This is the intended fix, not a breaking change.** A client that strongly wanted the old behaviour can send `frequency_auto_detect=false`.
- Existing clients that don't check for `warnings`, `detected_frequency`, or `cv_results` in the response continue to work; the new fields are additive.
- Old forecast records in `forecast_predictions` have `cv_results=null`; the schema already allows this.

---

## Rate-limiting

Existing `RateLimitForecast` middleware applies to `/run` and `/batch`. The new `/detect-frequency` is **not** rate-limited because it performs no fitting and is a pure data read.
