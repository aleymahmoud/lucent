# Phase 1 — Data Model

**Feature**: Fix Forecast Accuracy
**Plan**: [plan.md](./plan.md)

## Schema Changes

### `backend/app/schemas/forecast.py`

#### `ForecastRequest` (modified)

| Field | Change | Type | Default | Notes |
|-------|--------|------|---------|-------|
| `frequency` | UNCHANGED | `ForecastFrequency` | `D` | Still accepted; now treated as override when `frequency_auto_detect=False` |
| `frequency_auto_detect` | **NEW** | `bool` | `True` | When True, backend ignores `frequency` and auto-detects |
| `regressor_columns` | SEMANTICS CHANGE | `List[str]` | `[]` | No longer auto-populated server-side; only used if explicitly sent |
| `cross_validation` | UNCHANGED | `CrossValidationRequest?` | `None` | Already in schema; backend now honours it |
| `method_settings` | UNCHANGED | — | — | Per-method sub-objects unchanged |

#### `ForecastFrequency` enum (modified)

Add `Q` (Quarterly) and `Y` (Yearly) values to match the detection algorithm:

```python
class ForecastFrequency(str, Enum):
    D = "D"
    W = "W"
    M = "M"
    Q = "Q"  # NEW
    Y = "Y"  # NEW
```

#### `ForecastResultResponse` (modified)

| Field | Change | Type | Notes |
|-------|--------|------|-------|
| `detected_frequency` | **NEW** | `Optional[str]` | Result of auto-detect (e.g., "D" or "W") |
| `detected_seasonal_period` | **NEW** | `Optional[int]` | e.g., 7 for daily, 52 for weekly |
| `warnings` | **NEW** | `List[str]` | Non-fatal issues surfaced during execution |
| `cv_results` | POPULATED | `Optional[CrossValidationResultResponse]` | Already in schema; previously always None |
| (all existing fields) | UNCHANGED | — | — |

#### `CrossValidationResultResponse` (unchanged schema, behaviour changed)

Already exists and has the right shape. Behaviour change: the backend now actually populates it when `request.cross_validation.enabled=True`.

```python
class CrossValidationResultResponse(BaseModel):
    folds: int
    method: Literal["rolling", "expanding"]
    metrics_per_fold: List[Dict[str, float]]  # [{mae, rmse, mape}, ...]
    average_metrics: Dict[str, float]         # {mae, rmse, mape}
```

#### `FrequencyDetectionResponse` (new, for the new endpoint)

```python
class FrequencyDetectionResponse(BaseModel):
    detected_frequency: str            # "D" | "W" | "M" | "Q" | "Y"
    detected_seasonal_period: int      # 7, 52, 12, 4, or 1
    median_interval_days: float        # raw measurement
    observation_count: int
    irregular_intervals_pct: float     # % of intervals that deviate > 50% from median
    warnings: List[str] = []           # e.g., "Data has significant gaps"
```

---

### `backend/app/models/forecast_prediction.py` (no change)

`cv_results` JSON column already exists. Code will now write non-NULL values into it.

---

## New Backend Types

### `backend/app/forecasting/cross_validation.py` (new module)

```python
@dataclass
class CVFoldResult:
    fold_index: int
    train_size: int
    test_size: int
    mae: float
    rmse: float
    mape: float

@dataclass
class CVRunResult:
    folds: List[CVFoldResult]
    average_mae: float
    average_rmse: float
    average_mape: float
    method: str  # "rolling" | "expanding"
```

### `DataValidationResult` (new dataclass in `forecast_service.py`)

Wraps the pre-flight check outcome so warnings and blocking errors can be returned together:

```python
@dataclass
class DataValidationResult:
    blocking_error: Optional[str]      # None = OK to run; non-None = abort with this message
    warnings: List[str]
    detected_frequency: str
    detected_seasonal_period: int
    suggested_alternative_methods: List[str]  # populated on blocking_error
```

---

## Minimum Observation Rules (Reference Table)

These values come from the old R app and are the ground truth for the new validator:

| Method | Non-seasonal minimum | Seasonal minimum |
|--------|---------------------|------------------|
| ARIMA | 10 | `2 × s + 5` (s = seasonal period) |
| ETS | 10 | `2 × freq + 5` (freq = seasonal period) |
| Prophet | 15 | 15 (Prophet handles short seasonal itself) |

---

## Frontend State Changes

### `frontend/src/stores/forecastStore.ts` (Zustand)

Add:

- `detectedFrequency: string | null` — cached from last `/forecast/detect-frequency` call
- `forecastWarnings: string[]` — surfaced from last `/forecast/run` response

### `ForecastSettings.tsx` props

Add:

- `detectedFrequency?: string` — renders as "Detected: Daily" hint next to the dropdown
- `onAutoDetectChange?: (auto: boolean) => void`

### `ForecastWarnings.tsx` (new) props

```typescript
interface ForecastWarningsProps {
  warnings: string[];
  variant?: "pre-run" | "post-run";
}
```

---

## Frontend Types

```typescript
// frontend/src/types/forecast.ts (extended)

export interface FrequencyDetectionResponse {
  detected_frequency: "D" | "W" | "M" | "Q" | "Y";
  detected_seasonal_period: number;
  median_interval_days: number;
  observation_count: number;
  irregular_intervals_pct: number;
  warnings: string[];
}

export interface CrossValidationResult {
  folds: number;
  method: "rolling" | "expanding";
  metrics_per_fold: Array<{ mae: number; rmse: number; mape: number }>;
  average_metrics: { mae: number; rmse: number; mape: number };
}

// Added to existing ForecastResult interface:
export interface ForecastResult {
  // ... existing fields ...
  detected_frequency?: string;
  detected_seasonal_period?: number;
  warnings: string[];
  cv_results?: CrossValidationResult;
}
```

---

## Database

No schema changes. The `cv_results` JSON column in `forecast_predictions` already exists and is currently written as NULL; it will now hold the serialised `CVRunResult`.

Existing forecast records remain readable because the new response fields are all optional (`None`/`null` for old records).
