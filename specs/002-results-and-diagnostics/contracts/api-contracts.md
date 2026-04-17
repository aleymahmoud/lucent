# Phase 1 — API Contracts

**Feature**: Results & Diagnostics Parity
**Plan**: [../plan.md](../plan.md)

## Endpoint Summary

| Method | Path | Status | Purpose |
|--------|------|--------|---------|
| GET | `/api/v1/results/{forecast_id}` | MODIFIED | Existing; response grows `residuals`, new coefficient shape |
| GET | `/api/v1/results/{forecast_id}/summary` | MODIFIED | Existing; adds `forecast_statistics` field |
| GET | `/api/v1/results/{forecast_id}/cv` | UNCHANGED | Already returns cv_results; frontend now renders it |
| GET | `/api/v1/results/{forecast_id}/export/excel` | **NEW** | Streams single-entity .xlsx |
| GET | `/api/v1/results/batch/{batch_id}/export/excel` | **NEW** | Streams all-entities .xlsx |
| GET | `/api/v1/diagnostics/{forecast_id}` | MODIFIED | `residuals.is_synthetic` + `tests` populated |
| GET | `/api/v1/diagnostics/{forecast_id}/residuals` | MODIFIED | Same as above, scoped to residuals only |
| GET | `/api/v1/diagnostics/{forecast_id}/parameters` | MODIFIED | New `coefficients` list shape |
| POST | `/api/v1/diagnostics/compare` | UNCHANGED | Frontend now wires a UI |
| GET | `/api/v1/diagnostics/{forecast_id}/export` | **NEW** | HTML (or PDF when available) report |

---

## Modified: `GET /results/{forecast_id}/summary`

### Response (changes marked)

```jsonc
{
  "id": "uuid",
  "method": "arima" | "ets" | "prophet",
  "parameters": { ... },
  "coefficients": [                             // CHANGED: was Dict, now List
    {
      "name": "ar.L1",
      "estimate": -0.3245,
      "std_error": 0.089,                       // NEW
      "z_stat": -3.65,                          // NEW
      "p_value": 0.0003,                        // NEW
      "significant": true                       // NEW
    }
  ],
  "diagnostics": { ... },
  "regressors_used": [],
  "forecast_statistics": {                      // NEW
    "mean": 125.4,
    "median": 123.1,
    "min": 98.2,
    "max": 147.8,
    "q25": 115.3,
    "q75": 135.6,
    "iqr": 20.3,
    "average_interval_width": 28.5
  }
}
```

---

## Modified: `GET /diagnostics/{forecast_id}/residuals`

### Response (changes marked)

```jsonc
{
  "forecast_id": "uuid",
  "residuals": [0.12, -0.34, ...],              // Real values now
  "acf": [...],
  "pacf": [...],
  "ljung_box": { "statistic": 8.3, "p_value": 0.32 },
  "jarque_bera": { ... },
  "is_white_noise": true,
  "is_synthetic": false,                        // NEW - true for historical records
  "tests": [                                    // NEW
    {
      "test_name": "Ljung-Box",
      "statistic": 8.34,
      "p_value": 0.32,
      "interpretation": "No significant autocorrelation detected",
      "passes": true
    },
    {
      "test_name": "Breusch-Pagan",
      "statistic": 1.8,
      "p_value": 0.18,
      "interpretation": "Residual variance is constant (homoscedastic)",
      "passes": true
    },
    {
      "test_name": "Shapiro-Wilk",
      "statistic": 0.98,
      "p_value": 0.045,
      "interpretation": "Residuals are marginally non-normal",
      "passes": false
    }
  ]
}
```

---

## New: `GET /results/{forecast_id}/export/excel`

### Behavior

Streams a multi-sheet .xlsx file with:
- **Forecast**: Date, Value, Lower, Upper
- **Metrics**: metric → value (MAE, RMSE, MAPE, MSE, R², AIC, BIC)
- **Model Summary**: parameter → value + coefficient table (if applicable)
- **Cross-Validation**: per-fold + averages (only if `cv_results` exists)

### Response

- Content-Type: `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
- Content-Disposition: `attachment; filename="forecast_{entity}_{method}_{date}.xlsx"`

### Errors

| HTTP | Trigger |
|------|---------|
| 404 | Forecast not found or expired |
| 500 | openpyxl failure (rare) |

---

## New: `GET /results/batch/{batch_id}/export/excel`

### Behavior

Streams a multi-entity .xlsx with:
- **Summary**: entity, status, MAE, RMSE, MAPE for every entity
- **All Data**: combined data across all entities (Entity, Date, Type, Value, Lower, Upper)
- **{Entity_1}**, **{Entity_2}**, ... one sheet per entity (name truncated to 31 chars, deduplicated)

### Response

- Content-Type: `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
- Content-Disposition: `attachment; filename="forecast_batch_{date}.xlsx"`

---

## New: `GET /diagnostics/{forecast_id}/export`

### Query Parameters

- `format`: `"html"` (default) | `"pdf"` (returns 501 if PDF lib not installed)

### Behavior

Generates a self-contained HTML (or PDF) report containing:
- Model information (method, parameters)
- In-sample metrics
- CV results (if available)
- Residual plots (time series, histogram, QQ, ACF) as embedded SVG/PNG
- Test results (Ljung-Box, Breusch-Pagan, Shapiro-Wilk, Jarque-Bera)
- Quality indicator scores

### Response

- HTML: `Content-Type: text/html; charset=utf-8`
- PDF: `Content-Type: application/pdf`
- Content-Disposition: `attachment; filename="diagnostics_{entity}_{method}_{date}.{html|pdf}"`

### Errors

| HTTP | Trigger |
|------|---------|
| 501 | `format=pdf` but PDF library not installed. Body: `{"detail": "PDF export not available; use format=html"}` |
| 404 | Forecast not found |

---

## Backward Compatibility

- Existing clients that don't read `forecast_statistics`, `tests`, or `residuals` keep working.
- Existing records in Postgres without `residuals` still deserialize — the Diagnostics page sets `is_synthetic=true` and shows the banner.
- Coefficient field shape change: clients iterating `coefficients` as `Dict` would break. No known external clients today; we migrate the frontend in this feature.

---

## Rate Limiting

- New `/export/excel` endpoints: reuse existing forecast rate limiter (per tenant per minute).
- New `/diagnostics/{id}/export`: no rate limit (pure read + render).
