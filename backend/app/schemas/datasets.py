"""
Dataset Schemas - Pydantic models for data validation
"""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum


# ============================================
# Column Info Schema
# ============================================

class ColumnType(str, Enum):
    STRING = "string"
    INTEGER = "integer"
    FLOAT = "float"
    DATE = "date"
    DATETIME = "datetime"
    BOOLEAN = "boolean"
    UNKNOWN = "unknown"


class ColumnInfo(BaseModel):
    name: str
    type: ColumnType
    missing_count: int = 0
    unique_count: int = 0
    min: Optional[float] = None
    max: Optional[float] = None
    mean: Optional[float] = None
    std: Optional[float] = None
    sample_values: List[Any] = []


# ============================================
# Date Range Schema
# ============================================

class DateRange(BaseModel):
    start: Optional[str] = None
    end: Optional[str] = None


# ============================================
# Dataset Response Schemas
# ============================================

class DatasetBase(BaseModel):
    name: str
    filename: str


class DatasetCreate(DatasetBase):
    pass


class DatasetResponse(BaseModel):
    id: str
    name: str
    filename: str
    file_size: int
    file_type: str
    row_count: Optional[int] = None
    column_count: Optional[int] = None
    entity_column: Optional[str] = None
    date_column: Optional[str] = None
    value_column: Optional[str] = None
    columns: List[str] = []
    entities: List[str] = []
    date_range: DateRange = DateRange()
    uploaded_at: datetime
    uploaded_by: Optional[str] = None
    is_processed: bool = False
    is_active: bool = True

    class Config:
        from_attributes = True


class DatasetListResponse(BaseModel):
    datasets: List[DatasetResponse]
    total: int


# ============================================
# Data Preview Schema
# ============================================

class DataPreviewResponse(BaseModel):
    columns: List[str]
    data: List[Dict[str, Any]]
    total_rows: int
    page: int
    page_size: int
    total_pages: int


# ============================================
# Data Summary Schemas
# ============================================

class MissingValueInfo(BaseModel):
    column: str
    count: int
    percentage: float


class DataSummaryResponse(BaseModel):
    total_rows: int
    total_columns: int
    missing_values: int
    missing_percentage: float
    date_range: DateRange
    entity_count: int
    columns: List[ColumnInfo]
    missing_by_column: List[MissingValueInfo] = []
    memory_usage_mb: float = 0


# ============================================
# Data Structure Schema
# ============================================

class DataStructureResponse(BaseModel):
    columns: List[ColumnInfo]
    date_column: Optional[str] = None
    entity_column: Optional[str] = None
    value_column: Optional[str] = None
    detected_frequency: Optional[str] = None
    suggested_columns: Dict[str, Optional[str]] = {}


# ============================================
# Column Mapping Schema
# ============================================

class ColumnMappingRequest(BaseModel):
    date_column: str
    entity_column: Optional[str] = None
    value_column: str


class ColumnMappingResponse(BaseModel):
    id: str
    date_column: str
    entity_column: Optional[str] = None
    value_column: str
    entities: List[str] = []
    date_range: DateRange = DateRange()


# ============================================
# Upload Response Schema (includes preview + summary to avoid extra API calls)
# ============================================

class UploadResponse(BaseModel):
    id: str
    name: str
    filename: str
    file_size: int
    file_type: str
    row_count: int
    column_count: int
    columns: List[str]
    message: str = "File uploaded successfully"
    # Include preview and summary to avoid additional API calls
    preview: Optional[DataPreviewResponse] = None
    summary: Optional[DataSummaryResponse] = None
    date_column: Optional[str] = None
    entity_column: Optional[str] = None
    value_column: Optional[str] = None
    entities: List[str] = []


# ============================================
# Sample Data Schema
# ============================================

class SampleDataRequest(BaseModel):
    sample_type: str = "default"  # default, sales, energy, stock


class SampleDataResponse(BaseModel):
    id: str
    name: str
    filename: str
    row_count: int
    column_count: int
    entities: List[str]
    message: str = "Sample data loaded successfully"


# ============================================
# Template Download Schema
# ============================================

class TemplateInfo(BaseModel):
    name: str
    description: str
    columns: List[str]
    sample_rows: int
