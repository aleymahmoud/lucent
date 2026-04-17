# Phase 1 — Data Model

**Feature**: Results & Diagnostics Parity
**Plan**: [plan.md](./plan.md)

## Schema Changes

### `backend/app/schemas/forecast.py`

#### `ModelCoefficient` (new)

```python
class ModelCoefficient(BaseModel):
    name: str
    estimate: float
    std_error: Optional[float] = None
    z_stat: Optional[float] = None
    p_value: Optional[float] = None
    significant: Optional[bool] = None
```

#### `ModelSummaryResponse` (modified)

- `coefficients`: `Optional[Dict[str, float]]` → `Optional[List[ModelCoefficient]]` (new list shape)
- **NEW** `residuals`: `Optional[List[float]]` — populated for fresh forecasts, null for historical records

Backward compat: old coefficient dicts will be migrated on-read in the service layer (simple loop that wraps each float into a `ModelCoefficient(name=k, estimate=v)`), so existing DB records still deserialize.

---

### `backend/app/schemas/diagnostics.py`

#### `ResidualTestResult` (new)

```python
class ResidualTestResult(BaseModel):
    test_name: str               # "Ljung-Box" | "Breusch-Pagan" | "Shapiro-Wilk"
    statistic: float
    p_value: float
    interpretation: str          # human-readable
    passes: bool                 # convenience: p > 0.05
```

#### `ResidualAnalysisResponse` (modified)

- **NEW** `is_synthetic`: `bool` — True when backend could not retrieve stored residuals and returned null
- **NEW** `tests`: `List[ResidualTestResult]` — Ljung-Box + Breusch-Pagan + Shapiro-Wilk (populated when residuals available)
- `residuals`, `acf`, `pacf` behaviour unchanged structurally but now computed on real residuals

#### `ModelParametersResponse` (modified)

- `coefficients`: `Optional[Dict[str, float]]` → `Optional[List[ModelCoefficient]]`
- Keep `standard_errors: Optional[Dict[str, float]]` for backward compat with old records

#### `ForecastStatisticsResponse` (new)

```python
class ForecastStatisticsResponse(BaseModel):
    mean: float
    median: float
    min: float
    max: float
    q25: float
    q75: float
    iqr: float
    average_interval_width: float
```

---

### `backend/app/models/forecast_prediction.py` (no SQL change)

`model_summary` is a `JSON` column already. We just start writing the new `residuals` key into it.

---

## Frontend Types (`frontend/src/types/index.ts`)

```typescript
export interface ModelCoefficient {
  name: string;
  estimate: number;
  std_error?: number;
  z_stat?: number;
  p_value?: number;
  significant?: boolean;
}

export interface ResidualTestResult {
  test_name: string;
  statistic: number;
  p_value: number;
  interpretation: string;
  passes: boolean;
}

export interface ForecastStatistics {
  mean: number;
  median: number;
  min: number;
  max: number;
  q25: number;
  q75: number;
  iqr: number;
  average_interval_width: number;
}

// Extended ResidualAnalysisResponse:
export interface ResidualAnalysis {
  // ... existing ...
  is_synthetic: boolean;
  tests: ResidualTestResult[];
}

// Extended ForecastResult:
export interface ForecastResult {
  // ... existing ...
  forecast_statistics?: ForecastStatistics;  // populated by /results/{id}/summary enrichment
}
```

---

## Storage Locations

| Data | Redis | Postgres | TTL |
|------|-------|----------|-----|
| Residuals (fresh) | `forecast:{id}` JSON, under `model_summary.residuals` | `forecast_predictions.model_summary` JSON, same key | Redis 1h; Postgres permanent |
| CV results | `forecast:{id}` JSON, `cv_results` field (already exists) | `forecast_predictions.cv_results` JSON column | same |
| Forecast statistics | Computed on-the-fly in `results_service`; not persisted | — | — |
| Coefficient detail (new shape) | `model_summary.coefficients` list | Same JSON column | same |
