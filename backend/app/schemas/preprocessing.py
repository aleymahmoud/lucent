"""
Preprocessing Schemas - Pydantic models for preprocessing operations
"""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any, Literal
from datetime import datetime
from enum import Enum


# ============================================
# Enums
# ============================================

class MissingValueMethod(str, Enum):
    DROP = "drop"
    FILL_ZERO = "fill_zero"
    FILL_MEAN = "fill_mean"
    FILL_MEDIAN = "fill_median"
    FILL_MODE = "fill_mode"
    FORWARD_FILL = "forward_fill"
    BACKWARD_FILL = "backward_fill"
    LINEAR_INTERPOLATE = "linear_interpolate"
    SPLINE_INTERPOLATE = "spline_interpolate"


class DuplicateMethod(str, Enum):
    KEEP_ALL = "keep_all"
    KEEP_FIRST = "keep_first"
    KEEP_LAST = "keep_last"
    DROP_ALL = "drop_all"
    AGGREGATE_SUM = "aggregate_sum"
    AGGREGATE_MEAN = "aggregate_mean"


class OutlierMethod(str, Enum):
    IQR = "iqr"
    ZSCORE = "zscore"
    PERCENTILE = "percentile"


class OutlierAction(str, Enum):
    REMOVE = "remove"
    CAP = "cap"
    WINSORIZE = "winsorize"
    REPLACE_MEAN = "replace_mean"
    REPLACE_MEDIAN = "replace_median"
    FLAG_ONLY = "flag_only"


class AggregationFrequency(str, Enum):
    DAILY = "D"
    WEEKLY = "W"
    MONTHLY = "M"
    QUARTERLY = "Q"
    YEARLY = "Y"


class AggregationMethod(str, Enum):
    SUM = "sum"
    MEAN = "mean"
    MEDIAN = "median"
    MIN = "min"
    MAX = "max"
    FIRST = "first"
    LAST = "last"


# ============================================
# Request Schemas
# ============================================

class MissingValuesRequest(BaseModel):
    method: MissingValueMethod
    columns: Optional[List[str]] = None  # None means all columns
    fill_value: Optional[float] = None  # For custom fill value


class DuplicatesRequest(BaseModel):
    method: DuplicateMethod
    subset: Optional[List[str]] = None  # Columns to consider for duplicates


class OutlierRequest(BaseModel):
    method: OutlierMethod = OutlierMethod.IQR
    action: OutlierAction = OutlierAction.FLAG_ONLY
    columns: Optional[List[str]] = None  # None means all numeric columns
    threshold: float = 3.0  # IQR multiplier or Z-score threshold
    lower_percentile: float = 0.01  # For percentile method
    upper_percentile: float = 0.99


class ValueReplacementRequest(BaseModel):
    column: str
    old_value: Any
    new_value: Any
    match_type: Literal["exact", "contains", "regex"] = "exact"


class ConditionalReplacementRequest(BaseModel):
    """Conditional value replacement for time-series cleaning (from old R app).

    Replaces values in `column` that match a numeric condition with either
    a specific value or the mean/median of same-weekday values per-entity.
    """
    column: str
    condition: Literal["less_than", "greater_than", "equal_to", "between"]
    threshold1: float
    threshold2: Optional[float] = None  # Required for 'between'
    replacement_method: Literal["specific_value", "weekday_mean", "weekday_median"]
    replacement_value: Optional[float] = None  # Required for 'specific_value'


class ConditionalReplacementPreview(BaseModel):
    affected_count: int
    condition_text: str
    replacement_text: str
    weekday_breakdown: Optional[Dict[str, int]] = None
    warnings: List[str] = []


class TimeAggregationRequest(BaseModel):
    frequency: AggregationFrequency
    method: AggregationMethod = AggregationMethod.SUM
    date_column: str
    value_columns: Optional[List[str]] = None  # None means all numeric


class PreprocessingConfigRequest(BaseModel):
    """Full preprocessing configuration"""
    missing_values: Optional[MissingValuesRequest] = None
    duplicates: Optional[DuplicatesRequest] = None
    outliers: Optional[OutlierRequest] = None
    replacements: Optional[List[ValueReplacementRequest]] = None
    aggregation: Optional[TimeAggregationRequest] = None


# ============================================
# Response Schemas
# ============================================

class EntityInfo(BaseModel):
    name: str
    row_count: int
    date_range: Optional[Dict[str, str]] = None
    has_missing: bool = False
    missing_count: int = 0


class EntityListResponse(BaseModel):
    entities: List[EntityInfo]
    total: int
    entity_column: Optional[str] = None


class EntityStatsResponse(BaseModel):
    entity: str
    row_count: int
    column_count: int
    date_range: Optional[Dict[str, str]] = None
    statistics: Dict[str, Any]  # Per-column stats
    missing_values: Dict[str, int]
    outlier_count: Dict[str, int]


class PreprocessingResultResponse(BaseModel):
    success: bool
    message: str
    rows_before: int
    rows_after: int
    rows_affected: int
    preview_data: Optional[List[Dict[str, Any]]] = None


class MissingValuesAnalysis(BaseModel):
    column: str
    missing_count: int
    missing_percentage: float
    total_rows: int


class MissingValuesResponse(BaseModel):
    columns: List[MissingValuesAnalysis]
    total_missing: int
    total_cells: int
    overall_percentage: float


class OutlierInfo(BaseModel):
    column: str
    outlier_count: int
    outlier_percentage: float
    lower_bound: Optional[float] = None
    upper_bound: Optional[float] = None
    outlier_indices: List[int] = []


class OutliersResponse(BaseModel):
    method: str
    threshold: float
    columns: List[OutlierInfo]
    total_outliers: int


class DuplicatesResponse(BaseModel):
    duplicate_count: int
    duplicate_percentage: float
    duplicate_rows: Optional[List[int]] = None


class PreprocessedDataResponse(BaseModel):
    columns: List[str]
    data: List[Dict[str, Any]]
    total_rows: int
    page: int
    page_size: int
    total_pages: int
    applied_operations: List[str] = []


class ValueReplacementResponse(BaseModel):
    success: bool
    message: str
    rows_affected: int
    column: str
    old_value: Any
    new_value: Any
