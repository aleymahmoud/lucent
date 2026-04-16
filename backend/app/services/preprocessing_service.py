"""
Preprocessing Service - Data cleaning and transformation operations
"""
import pandas as pd
import numpy as np
from typing import Optional, List, Dict, Any, Tuple
from datetime import datetime
import json
import logging

from app.db.redis_client import get_redis
from app.schemas.preprocessing import (
    MissingValueMethod, DuplicateMethod, OutlierMethod, OutlierAction,
    AggregationFrequency, AggregationMethod,
    MissingValuesRequest, DuplicatesRequest, OutlierRequest,
    ValueReplacementRequest, ConditionalReplacementRequest, ConditionalReplacementPreview,
    TimeAggregationRequest,
    EntityInfo, EntityStatsResponse, MissingValuesAnalysis,
    OutlierInfo, PreprocessingResultResponse
)

logger = logging.getLogger(__name__)

# Redis key prefixes
REDIS_PREPROCESSED_PREFIX = "preprocessed:"
REDIS_PREPROCESSED_TTL = 3600 * 2  # 2 hours


class PreprocessingService:
    """Service for handling preprocessing operations on datasets"""

    def __init__(self, tenant_id: str, user_id: Optional[str] = None):
        self.tenant_id = tenant_id
        self.user_id = user_id

    # ============================================
    # Data Retrieval
    # ============================================

    async def get_dataset_dataframe(self, dataset_id: str) -> Optional[pd.DataFrame]:
        """Retrieve dataset as DataFrame from Redis"""
        try:
            redis = await get_redis()
            if redis is None:
                return None

            # Try preprocessed data first
            preprocessed_key = f"{REDIS_PREPROCESSED_PREFIX}{dataset_id}"
            data = await redis.get(preprocessed_key)

            if not data:
                # Fall back to original dataset
                original_key = f"dataset:{dataset_id}"
                data = await redis.get(original_key)

            if data:
                if isinstance(data, bytes):
                    data = data.decode('utf-8')
                df_dict = json.loads(data)

                # Handle both 'split' and 'dict' orientations
                if isinstance(df_dict, dict) and 'columns' in df_dict and 'data' in df_dict:
                    # Data is in 'split' orientation
                    from io import StringIO
                    return pd.read_json(StringIO(data), orient='split')
                else:
                    # Data is in 'dict' orientation (column names as keys)
                    return pd.DataFrame(df_dict)

            return None
        except Exception as e:
            logger.error(f"Error retrieving dataset: {e}")
            return None

    async def save_preprocessed_data(
        self,
        dataset_id: str,
        df: pd.DataFrame,
        entity_id: Optional[str] = None
    ) -> bool:
        """Save preprocessed DataFrame to Redis"""
        try:
            redis = await get_redis()
            if redis is None:
                return False

            key = f"{REDIS_PREPROCESSED_PREFIX}{dataset_id}"
            if entity_id:
                key = f"{key}:{entity_id}"

            # Convert DataFrame to JSON-serializable format
            data = df.to_dict(orient='records')
            await redis.set(key, json.dumps(data, default=str), ex=REDIS_PREPROCESSED_TTL)
            return True
        except Exception as e:
            logger.error(f"Error saving preprocessed data: {e}")
            return False

    # ============================================
    # Entity Operations
    # ============================================

    async def get_entities(
        self,
        dataset_id: str,
        entity_column: Optional[str] = None
    ) -> Tuple[List[EntityInfo], Optional[str]]:
        """Get list of entities in a dataset"""
        df = await self.get_dataset_dataframe(dataset_id)
        if df is None:
            return [], None

        # Try to detect entity column if not provided
        if not entity_column:
            entity_column = self._detect_entity_column(df)

        if not entity_column or entity_column not in df.columns:
            # No entity column - treat entire dataset as single entity
            return [EntityInfo(
                name="All Data",
                row_count=len(df),
                has_missing=df.isnull().any().any(),
                missing_count=int(df.isnull().sum().sum())
            )], None

        entities = []
        for entity_name in df[entity_column].unique():
            entity_df = df[df[entity_column] == entity_name]
            date_col = self._detect_date_column(entity_df)
            date_range = None
            if date_col:
                try:
                    dates = pd.to_datetime(entity_df[date_col], errors='coerce')
                    valid_dates = dates.dropna()
                    if len(valid_dates) > 0:
                        date_range = {
                            "start": valid_dates.min().strftime("%Y-%m-%d"),
                            "end": valid_dates.max().strftime("%Y-%m-%d")
                        }
                except Exception:
                    pass

            entities.append(EntityInfo(
                name=str(entity_name),
                row_count=len(entity_df),
                date_range=date_range,
                has_missing=entity_df.isnull().any().any(),
                missing_count=int(entity_df.isnull().sum().sum())
            ))

        return entities, entity_column

    async def get_entity_data(
        self,
        dataset_id: str,
        entity_id: str,
        entity_column: Optional[str] = None
    ) -> Optional[pd.DataFrame]:
        """Get data for a specific entity, checking per-entity preprocessed cache first"""
        # Check for per-entity preprocessed data first
        if entity_id and entity_id != "All Data":
            try:
                redis = await get_redis()
                if redis:
                    entity_key = f"{REDIS_PREPROCESSED_PREFIX}{dataset_id}:{entity_id}"
                    data = await redis.get(entity_key)
                    if data:
                        if isinstance(data, bytes):
                            data = data.decode('utf-8')
                        parsed = json.loads(data)
                        if isinstance(parsed, list):
                            return pd.DataFrame(parsed)
                        elif isinstance(parsed, dict) and 'columns' in parsed:
                            from io import StringIO
                            return pd.read_json(StringIO(data if isinstance(data, str) else json.dumps(parsed)), orient='split')
                        else:
                            return pd.DataFrame(parsed)
            except Exception as e:
                logger.debug(f"No per-entity preprocessed data for {entity_id}: {e}")

        df = await self.get_dataset_dataframe(dataset_id)
        if df is None:
            return None

        if entity_id == "All Data" or not entity_column:
            return df

        if entity_column not in df.columns:
            return df

        # Compare as strings to handle int/str mismatch
        return df[df[entity_column].astype(str) == str(entity_id)].copy()

    async def get_entity_stats(
        self,
        dataset_id: str,
        entity_id: str,
        entity_column: Optional[str] = None
    ) -> Optional[EntityStatsResponse]:
        """Get statistics for a specific entity"""
        df = await self.get_entity_data(dataset_id, entity_id, entity_column)
        if df is None:
            return None

        # Compute statistics
        stats = {}
        missing = {}
        outliers = {}

        for col in df.columns:
            col_data = df[col]
            missing[col] = int(col_data.isnull().sum())

            if pd.api.types.is_numeric_dtype(col_data):
                valid_data = col_data.dropna()
                if len(valid_data) > 0:
                    stats[col] = {
                        "mean": float(valid_data.mean()),
                        "std": float(valid_data.std()) if len(valid_data) > 1 else 0,
                        "min": float(valid_data.min()),
                        "max": float(valid_data.max()),
                        "median": float(valid_data.median()),
                        "q1": float(valid_data.quantile(0.25)),
                        "q3": float(valid_data.quantile(0.75)),
                    }
                    # Count outliers using IQR
                    q1 = valid_data.quantile(0.25)
                    q3 = valid_data.quantile(0.75)
                    iqr = q3 - q1
                    outliers[col] = int(((valid_data < q1 - 1.5 * iqr) | (valid_data > q3 + 1.5 * iqr)).sum())
                else:
                    stats[col] = {"mean": None, "std": None, "min": None, "max": None}
                    outliers[col] = 0
            else:
                stats[col] = {
                    "unique_count": int(col_data.nunique()),
                    "top_value": str(col_data.mode().iloc[0]) if len(col_data.mode()) > 0 else None,
                }
                outliers[col] = 0

        # Get date range
        date_col = self._detect_date_column(df)
        date_range = None
        if date_col:
            try:
                dates = pd.to_datetime(df[date_col], errors='coerce')
                valid_dates = dates.dropna()
                if len(valid_dates) > 0:
                    date_range = {
                        "start": valid_dates.min().strftime("%Y-%m-%d"),
                        "end": valid_dates.max().strftime("%Y-%m-%d")
                    }
            except Exception:
                pass

        return EntityStatsResponse(
            entity=entity_id,
            row_count=len(df),
            column_count=len(df.columns),
            date_range=date_range,
            statistics=stats,
            missing_values=missing,
            outlier_count=outliers
        )

    # ============================================
    # Missing Values
    # ============================================

    async def analyze_missing_values(
        self,
        dataset_id: str,
        entity_id: Optional[str] = None,
        entity_column: Optional[str] = None
    ) -> Dict[str, Any]:
        """Analyze missing values in dataset"""
        if entity_id:
            df = await self.get_entity_data(dataset_id, entity_id, entity_column)
        else:
            df = await self.get_dataset_dataframe(dataset_id)

        if df is None:
            return {"columns": [], "total_missing": 0, "total_cells": 0, "overall_percentage": 0}

        columns = []
        total_rows = len(df)

        for col in df.columns:
            missing_count = int(df[col].isnull().sum())
            columns.append(MissingValuesAnalysis(
                column=col,
                missing_count=missing_count,
                missing_percentage=round((missing_count / total_rows) * 100, 2) if total_rows > 0 else 0,
                total_rows=total_rows
            ))

        total_missing = int(df.isnull().sum().sum())
        total_cells = df.size

        return {
            "columns": [c.model_dump() for c in columns],
            "total_missing": total_missing,
            "total_cells": total_cells,
            "overall_percentage": round((total_missing / total_cells) * 100, 2) if total_cells > 0 else 0
        }

    async def handle_missing_values(
        self,
        dataset_id: str,
        request: MissingValuesRequest,
        entity_id: Optional[str] = None,
        entity_column: Optional[str] = None
    ) -> PreprocessingResultResponse:
        """Handle missing values in dataset"""
        if entity_id:
            df = await self.get_entity_data(dataset_id, entity_id, entity_column)
        else:
            df = await self.get_dataset_dataframe(dataset_id)

        if df is None:
            return PreprocessingResultResponse(
                success=False, message="Dataset not found",
                rows_before=0, rows_after=0, rows_affected=0
            )

        rows_before = len(df)
        columns = request.columns or df.columns.tolist()
        # Filter to columns that actually exist in the DataFrame
        columns = [c for c in columns if c in df.columns]
        # Capture missing count before processing for accurate rows_affected
        missing_before = int(df[columns].isnull().sum().sum())

        # Order-dependent methods need date sorting
        order_dependent = (
            MissingValueMethod.FORWARD_FILL,
            MissingValueMethod.BACKWARD_FILL,
            MissingValueMethod.LINEAR_INTERPOLATE,
            MissingValueMethod.SPLINE_INTERPOLATE,
        )
        date_col = self._detect_date_column(df)
        if date_col and request.method in order_dependent:
            df = df.sort_values(date_col).reset_index(drop=True)

        # Detect entity column for per-entity grouping (dataset-wide mode only)
        entity_col = None if entity_id else self._detect_entity_column(df)

        try:
            if request.method == MissingValueMethod.DROP:
                df = df.dropna(subset=columns)
            elif request.method == MissingValueMethod.FILL_ZERO:
                df[columns] = df[columns].fillna(0)
            elif request.method == MissingValueMethod.FILL_MEAN:
                for col in columns:
                    if pd.api.types.is_numeric_dtype(df[col]):
                        if entity_col:
                            df[col] = df.groupby(entity_col)[col].transform(
                                lambda g: g.fillna(g.mean())
                            )
                        else:
                            df[col] = df[col].fillna(df[col].mean())
            elif request.method == MissingValueMethod.FILL_MEDIAN:
                for col in columns:
                    if pd.api.types.is_numeric_dtype(df[col]):
                        if entity_col:
                            df[col] = df.groupby(entity_col)[col].transform(
                                lambda g: g.fillna(g.median())
                            )
                        else:
                            df[col] = df[col].fillna(df[col].median())
            elif request.method == MissingValueMethod.FILL_MODE:
                for col in columns:
                    if entity_col:
                        def _fill_mode(g):
                            mode_vals = g.mode()
                            if len(mode_vals) > 0:
                                return g.fillna(mode_vals.iloc[0])
                            return g
                        df[col] = df.groupby(entity_col)[col].transform(_fill_mode)
                    else:
                        mode_val = df[col].mode()
                        if len(mode_val) > 0:
                            df[col] = df[col].fillna(mode_val.iloc[0])
            elif request.method == MissingValueMethod.FORWARD_FILL:
                if entity_col:
                    for col in columns:
                        df[col] = df.groupby(entity_col)[col].transform(lambda g: g.ffill())
                else:
                    df[columns] = df[columns].ffill()
            elif request.method == MissingValueMethod.BACKWARD_FILL:
                if entity_col:
                    for col in columns:
                        df[col] = df.groupby(entity_col)[col].transform(lambda g: g.bfill())
                else:
                    df[columns] = df[columns].bfill()
            elif request.method == MissingValueMethod.LINEAR_INTERPOLATE:
                for col in columns:
                    if pd.api.types.is_numeric_dtype(df[col]):
                        if entity_col:
                            df[col] = df.groupby(entity_col)[col].transform(
                                lambda g: g.interpolate(method='linear').bfill().ffill() if g.notna().sum() >= 2 else g
                            )
                        else:
                            if df[col].notna().sum() >= 2:
                                df[col] = df[col].interpolate(method='linear').bfill().ffill()
            elif request.method == MissingValueMethod.SPLINE_INTERPOLATE:
                for col in columns:
                    if pd.api.types.is_numeric_dtype(df[col]):
                        if entity_col:
                            def _spline_or_fallback(g):
                                non_null = g.notna().sum()
                                if non_null >= 3:
                                    return g.interpolate(method='spline', order=2).bfill().ffill()
                                elif non_null >= 2:
                                    return g.interpolate(method='linear').bfill().ffill()
                                return g
                            df[col] = df.groupby(entity_col)[col].transform(_spline_or_fallback)
                        else:
                            non_null = df[col].notna().sum()
                            if non_null >= 3:
                                df[col] = df[col].interpolate(method='spline', order=2).bfill().ffill()
                            elif non_null >= 2:
                                df[col] = df[col].interpolate(method='linear').bfill().ffill()

            rows_after = len(df)
            missing_after = int(df[columns].isnull().sum().sum())
            rows_affected = (rows_before - rows_after) if request.method == MissingValueMethod.DROP else (missing_before - missing_after)

            # Save preprocessed data
            await self.save_preprocessed_data(dataset_id, df, entity_id)

            return PreprocessingResultResponse(
                success=True,
                message=f"Missing values handled using {request.method.value}",
                rows_before=rows_before,
                rows_after=rows_after,
                rows_affected=rows_affected,
                preview_data=df.head(10).to_dict(orient='records')
            )
        except Exception as e:
            logger.error(f"Error handling missing values: {e}")
            return PreprocessingResultResponse(
                success=False, message=str(e),
                rows_before=rows_before, rows_after=rows_before, rows_affected=0
            )

    # ============================================
    # Duplicates
    # ============================================

    async def analyze_duplicates(
        self,
        dataset_id: str,
        subset: Optional[List[str]] = None,
        entity_id: Optional[str] = None,
        entity_column: Optional[str] = None
    ) -> Dict[str, Any]:
        """Analyze duplicates in dataset"""
        if entity_id:
            df = await self.get_entity_data(dataset_id, entity_id, entity_column)
        else:
            df = await self.get_dataset_dataframe(dataset_id)

        if df is None:
            return {"duplicate_count": 0, "duplicate_percentage": 0}

        # Auto-detect Entity+Date columns as default subset (matches old app behavior)
        if not subset:
            entity_col = self._detect_entity_column(df)
            date_col = self._detect_date_column(df)
            if entity_col and date_col:
                subset = [entity_col, date_col]

        duplicates = df.duplicated(subset=subset, keep=False)
        duplicate_count = int(duplicates.sum())

        return {
            "duplicate_count": duplicate_count,
            "duplicate_percentage": round((duplicate_count / len(df)) * 100, 2) if len(df) > 0 else 0,
            "duplicate_rows": df[duplicates].index.tolist()[:100]  # Limit to 100
        }

    async def handle_duplicates(
        self,
        dataset_id: str,
        request: DuplicatesRequest,
        entity_id: Optional[str] = None,
        entity_column: Optional[str] = None
    ) -> PreprocessingResultResponse:
        """Handle duplicates in dataset"""
        if entity_id:
            df = await self.get_entity_data(dataset_id, entity_id, entity_column)
        else:
            df = await self.get_dataset_dataframe(dataset_id)

        if df is None:
            return PreprocessingResultResponse(
                success=False, message="Dataset not found",
                rows_before=0, rows_after=0, rows_affected=0
            )

        rows_before = len(df)

        # Auto-detect Entity+Date columns as default subset (matches old app behavior)
        subset = request.subset
        if not subset:
            entity_col = self._detect_entity_column(df)
            date_col = self._detect_date_column(df)
            if entity_col and date_col:
                subset = [entity_col, date_col]

        try:
            if request.method == DuplicateMethod.KEEP_ALL:
                pass  # No-op, keep all rows
            elif request.method == DuplicateMethod.KEEP_FIRST:
                df = df.drop_duplicates(subset=subset, keep='first')
            elif request.method == DuplicateMethod.KEEP_LAST:
                df = df.drop_duplicates(subset=subset, keep='last')
            elif request.method == DuplicateMethod.DROP_ALL:
                df = df.drop_duplicates(subset=subset, keep=False)
            elif request.method in (DuplicateMethod.AGGREGATE_SUM, DuplicateMethod.AGGREGATE_MEAN):
                if subset:
                    agg_func = 'sum' if request.method == DuplicateMethod.AGGREGATE_SUM else 'mean'
                    numeric_cols = [c for c in df.select_dtypes(include=[np.number]).columns if c not in subset]
                    non_numeric_cols = [c for c in df.columns if c not in subset and c not in numeric_cols]
                    # Build aggregation: numeric cols get sum/mean, non-numeric get first value
                    agg_dict = {c: agg_func for c in numeric_cols}
                    agg_dict.update({c: 'first' for c in non_numeric_cols})
                    df = df.groupby(subset, as_index=False).agg(agg_dict)

            rows_after = len(df)
            await self.save_preprocessed_data(dataset_id, df, entity_id)

            return PreprocessingResultResponse(
                success=True,
                message=f"Duplicates handled using {request.method.value}",
                rows_before=rows_before,
                rows_after=rows_after,
                rows_affected=rows_before - rows_after,
                preview_data=df.head(10).to_dict(orient='records')
            )
        except Exception as e:
            logger.error(f"Error handling duplicates: {e}")
            return PreprocessingResultResponse(
                success=False, message=str(e),
                rows_before=rows_before, rows_after=rows_before, rows_affected=0
            )

    # ============================================
    # Outliers
    # ============================================

    def _compute_outlier_bounds(
        self, col_data: pd.Series, method: 'OutlierMethod', threshold: float,
        lower_percentile: float = 0.01, upper_percentile: float = 0.99
    ) -> tuple:
        """Compute outlier bounds for a single column/group"""
        if method == OutlierMethod.IQR:
            q1 = col_data.quantile(0.25)
            q3 = col_data.quantile(0.75)
            iqr = q3 - q1
            return q1 - threshold * iqr, q3 + threshold * iqr
        elif method == OutlierMethod.ZSCORE:
            mean = col_data.mean()
            std = col_data.std()
            if std == 0:
                return mean, mean
            return mean - threshold * std, mean + threshold * std
        else:  # percentile
            return col_data.quantile(lower_percentile), col_data.quantile(upper_percentile)

    async def detect_outliers(
        self,
        dataset_id: str,
        request: OutlierRequest,
        entity_id: Optional[str] = None,
        entity_column: Optional[str] = None
    ) -> Dict[str, Any]:
        """Detect outliers in dataset, per-entity when in dataset-wide mode"""
        if entity_id:
            df = await self.get_entity_data(dataset_id, entity_id, entity_column)
        else:
            df = await self.get_dataset_dataframe(dataset_id)

        if df is None:
            return {"method": request.method.value, "threshold": request.threshold, "columns": [], "total_outliers": 0, "total_rows": 0}

        total_rows = len(df)
        columns = request.columns or df.select_dtypes(include=[np.number]).columns.tolist()
        # Per-entity detection when processing whole dataset
        entity_col = None if entity_id else self._detect_entity_column(df)
        outlier_info = []
        total_outliers = 0

        for col in columns:
            if col not in df.columns or not pd.api.types.is_numeric_dtype(df[col]):
                continue

            col_data = df[col].dropna()
            if len(col_data) == 0:
                continue

            # Build outlier mask per-entity or globally
            if entity_col:
                outlier_mask = pd.Series(False, index=df.index)
                for _, group in df.groupby(entity_col):
                    g_data = group[col].dropna()
                    if len(g_data) == 0:
                        continue
                    lb, ub = self._compute_outlier_bounds(g_data, request.method, request.threshold, request.lower_percentile, request.upper_percentile)
                    g_mask = (group[col] < lb) | (group[col] > ub)
                    outlier_mask.loc[group.index] = g_mask
                # Use global bounds for display (average of per-entity bounds)
                lower_bound, upper_bound = self._compute_outlier_bounds(col_data, request.method, request.threshold, request.lower_percentile, request.upper_percentile)
            else:
                lower_bound, upper_bound = self._compute_outlier_bounds(col_data, request.method, request.threshold, request.lower_percentile, request.upper_percentile)
                outlier_mask = (df[col] < lower_bound) | (df[col] > upper_bound)

            outlier_count = int(outlier_mask.sum())
            total_outliers += outlier_count

            outlier_info.append(OutlierInfo(
                column=col,
                outlier_count=outlier_count,
                outlier_percentage=round((outlier_count / len(df)) * 100, 2),
                lower_bound=float(lower_bound),
                upper_bound=float(upper_bound),
                outlier_indices=df[outlier_mask].index.tolist()[:50]
            ).model_dump())

        return {
            "method": request.method.value,
            "threshold": request.threshold,
            "columns": outlier_info,
            "total_outliers": total_outliers,
            "total_rows": total_rows
        }

    async def handle_outliers(
        self,
        dataset_id: str,
        request: OutlierRequest,
        entity_id: Optional[str] = None,
        entity_column: Optional[str] = None
    ) -> PreprocessingResultResponse:
        """Handle outliers in dataset, per-entity when in dataset-wide mode"""
        if entity_id:
            df = await self.get_entity_data(dataset_id, entity_id, entity_column)
        else:
            df = await self.get_dataset_dataframe(dataset_id)

        if df is None:
            return PreprocessingResultResponse(
                success=False, message="Dataset not found",
                rows_before=0, rows_after=0, rows_affected=0
            )

        rows_before = len(df)
        columns = request.columns or df.select_dtypes(include=[np.number]).columns.tolist()
        entity_col = None if entity_id else self._detect_entity_column(df)
        total_affected = 0

        try:
            for col in columns:
                if col not in df.columns or not pd.api.types.is_numeric_dtype(df[col]):
                    continue

                col_data = df[col].dropna()
                if len(col_data) == 0:
                    continue

                # Build outlier mask — per-entity or global
                if entity_col:
                    outlier_mask = pd.Series(False, index=df.index)
                    for ent_val, group in df.groupby(entity_col):
                        g_data = group[col].dropna()
                        if len(g_data) == 0:
                            continue
                        lb, ub = self._compute_outlier_bounds(g_data, request.method, request.threshold, request.lower_percentile, request.upper_percentile)
                        g_mask = (group[col] < lb) | (group[col] > ub)
                        outlier_mask.loc[group.index] = g_mask
                else:
                    lb, ub = self._compute_outlier_bounds(col_data, request.method, request.threshold, request.lower_percentile, request.upper_percentile)
                    outlier_mask = (df[col] < lb) | (df[col] > ub)

                n_outliers = int(outlier_mask.sum())
                total_affected += n_outliers

                if request.action == OutlierAction.REMOVE:
                    df = df[~outlier_mask]
                elif request.action == OutlierAction.CAP:
                    if entity_col:
                        for _, group in df.groupby(entity_col):
                            g_data = group[col].dropna()
                            if len(g_data) == 0:
                                continue
                            g_lb, g_ub = self._compute_outlier_bounds(g_data, request.method, request.threshold, request.lower_percentile, request.upper_percentile)
                            df.loc[(df.index.isin(group.index)) & (df[col] < g_lb), col] = g_lb
                            df.loc[(df.index.isin(group.index)) & (df[col] > g_ub), col] = g_ub
                    else:
                        df.loc[df[col] < lb, col] = lb
                        df.loc[df[col] > ub, col] = ub
                elif request.action == OutlierAction.WINSORIZE:
                    # Cap at 5th/95th percentile of non-outlier values per entity
                    if entity_col:
                        for _, group in df.groupby(entity_col):
                            g_non_outlier = group.loc[~outlier_mask.loc[group.index], col].dropna()
                            if len(g_non_outlier) == 0:
                                continue
                            p05 = g_non_outlier.quantile(0.05)
                            p95 = g_non_outlier.quantile(0.95)
                            g_outlier_mask = outlier_mask.loc[group.index]
                            df.loc[(df.index.isin(group.index)) & g_outlier_mask & (df[col] < p05), col] = p05
                            df.loc[(df.index.isin(group.index)) & g_outlier_mask & (df[col] > p95), col] = p95
                    else:
                        non_outlier_data = df.loc[~outlier_mask, col].dropna()
                        if len(non_outlier_data) > 0:
                            p05 = non_outlier_data.quantile(0.05)
                            p95 = non_outlier_data.quantile(0.95)
                            df.loc[outlier_mask & (df[col] < p05), col] = p05
                            df.loc[outlier_mask & (df[col] > p95), col] = p95
                elif request.action == OutlierAction.REPLACE_MEAN:
                    # Replace with mean of NON-outlier values per entity
                    if entity_col:
                        for _, group in df.groupby(entity_col):
                            g_non_outlier_mean = group.loc[~outlier_mask.loc[group.index], col].mean()
                            g_outlier_idx = group.index[outlier_mask.loc[group.index]]
                            df.loc[g_outlier_idx, col] = g_non_outlier_mean
                    else:
                        non_outlier_mean = df.loc[~outlier_mask, col].mean()
                        df.loc[outlier_mask, col] = non_outlier_mean
                elif request.action == OutlierAction.REPLACE_MEDIAN:
                    # Replace with median of NON-outlier values per entity
                    if entity_col:
                        for _, group in df.groupby(entity_col):
                            g_non_outlier_median = group.loc[~outlier_mask.loc[group.index], col].median()
                            g_outlier_idx = group.index[outlier_mask.loc[group.index]]
                            df.loc[g_outlier_idx, col] = g_non_outlier_median
                    else:
                        non_outlier_median = df.loc[~outlier_mask, col].median()
                        df.loc[outlier_mask, col] = non_outlier_median
                # FLAG_ONLY does nothing to the data

            rows_after = len(df)
            await self.save_preprocessed_data(dataset_id, df, entity_id)

            return PreprocessingResultResponse(
                success=True,
                message=f"Outliers handled using {request.method.value} + {request.action.value}",
                rows_before=rows_before,
                rows_after=rows_after,
                rows_affected=total_affected,
                preview_data=df.head(10).to_dict(orient='records')
            )
        except Exception as e:
            logger.error(f"Error handling outliers: {e}")
            return PreprocessingResultResponse(
                success=False, message=str(e),
                rows_before=rows_before, rows_after=rows_before, rows_affected=0
            )

    # ============================================
    # Time Aggregation
    # ============================================

    async def aggregate_time(
        self,
        dataset_id: str,
        request: TimeAggregationRequest,
        entity_id: Optional[str] = None,
        entity_column: Optional[str] = None
    ) -> PreprocessingResultResponse:
        """Aggregate data by time frequency"""
        if entity_id:
            df = await self.get_entity_data(dataset_id, entity_id, entity_column)
        else:
            df = await self.get_dataset_dataframe(dataset_id)

        if df is None:
            return PreprocessingResultResponse(
                success=False, message="Dataset not found",
                rows_before=0, rows_after=0, rows_affected=0
            )

        rows_before = len(df)

        try:
            # Convert date column
            df[request.date_column] = pd.to_datetime(df[request.date_column], errors='coerce')

            # Set date as index
            df = df.set_index(request.date_column)

            # Get value columns
            value_cols = request.value_columns or df.select_dtypes(include=[np.number]).columns.tolist()

            # Get aggregation function
            agg_func = request.method.value

            # Resample and aggregate
            if entity_column and entity_column in df.columns:
                # Group by entity then resample
                df = df.groupby(entity_column).resample(request.frequency.value)[value_cols].agg(agg_func)
                df = df.reset_index()
            else:
                df = df.resample(request.frequency.value)[value_cols].agg(agg_func)
                df = df.reset_index()

            rows_after = len(df)
            await self.save_preprocessed_data(dataset_id, df, entity_id)

            return PreprocessingResultResponse(
                success=True,
                message=f"Data aggregated to {request.frequency.value} using {request.method.value}",
                rows_before=rows_before,
                rows_after=rows_after,
                rows_affected=rows_before - rows_after,
                preview_data=df.head(10).to_dict(orient='records')
            )
        except Exception as e:
            logger.error(f"Error aggregating time: {e}")
            return PreprocessingResultResponse(
                success=False, message=str(e),
                rows_before=rows_before, rows_after=rows_before, rows_affected=0
            )

    # ============================================
    # Value Replacement
    # ============================================

    async def replace_values(
        self,
        dataset_id: str,
        request: ValueReplacementRequest,
        entity_id: Optional[str] = None,
        entity_column: Optional[str] = None
    ) -> PreprocessingResultResponse:
        """Replace values in a column based on match criteria"""
        if entity_id:
            df = await self.get_entity_data(dataset_id, entity_id, entity_column)
        else:
            df = await self.get_dataset_dataframe(dataset_id)

        if df is None:
            return PreprocessingResultResponse(
                success=False, message="Dataset not found",
                rows_before=0, rows_after=0, rows_affected=0
            )

        rows_before = len(df)

        if request.column not in df.columns:
            return PreprocessingResultResponse(
                success=False, message=f"Column '{request.column}' not found",
                rows_before=rows_before, rows_after=rows_before, rows_affected=0
            )

        try:
            col = request.column
            old_val = request.old_value
            new_val = request.new_value

            if request.match_type == "exact":
                # Exact match replacement
                mask = df[col] == old_val
                rows_affected = int(mask.sum())
                df.loc[mask, col] = new_val
            elif request.match_type == "contains":
                # String contains replacement
                if df[col].dtype == 'object':
                    mask = df[col].astype(str).str.contains(str(old_val), na=False)
                    rows_affected = int(mask.sum())
                    df.loc[mask, col] = df.loc[mask, col].astype(str).str.replace(str(old_val), str(new_val), regex=False)
                else:
                    return PreprocessingResultResponse(
                        success=False, message="'contains' match type only works with string columns",
                        rows_before=rows_before, rows_after=rows_before, rows_affected=0
                    )
            elif request.match_type == "regex":
                # Regex replacement
                if df[col].dtype == 'object':
                    mask = df[col].astype(str).str.contains(str(old_val), na=False, regex=True)
                    rows_affected = int(mask.sum())
                    df[col] = df[col].astype(str).str.replace(str(old_val), str(new_val), regex=True)
                else:
                    return PreprocessingResultResponse(
                        success=False, message="'regex' match type only works with string columns",
                        rows_before=rows_before, rows_after=rows_before, rows_affected=0
                    )
            else:
                rows_affected = 0

            await self.save_preprocessed_data(dataset_id, df, entity_id)

            return PreprocessingResultResponse(
                success=True,
                message=f"Replaced {rows_affected} values in column '{col}'",
                rows_before=rows_before,
                rows_after=len(df),
                rows_affected=rows_affected,
                preview_data=df.head(10).to_dict(orient='records')
            )
        except Exception as e:
            logger.error(f"Error replacing values: {e}")
            return PreprocessingResultResponse(
                success=False, message=str(e),
                rows_before=rows_before, rows_after=rows_before, rows_affected=0
            )

    # ============================================
    # Conditional Value Replacement (time-series)
    # ============================================

    def _build_condition_mask(self, series: pd.Series, request: ConditionalReplacementRequest) -> pd.Series:
        """Build boolean mask identifying values that match the condition"""
        if request.condition == "less_than":
            return series < request.threshold1
        elif request.condition == "greater_than":
            return series > request.threshold1
        elif request.condition == "equal_to":
            return series == request.threshold1
        elif request.condition == "between":
            t2 = request.threshold2 if request.threshold2 is not None else request.threshold1
            lo, hi = min(request.threshold1, t2), max(request.threshold1, t2)
            return (series >= lo) & (series <= hi)
        return pd.Series(False, index=series.index)

    def _describe_condition(self, request: ConditionalReplacementRequest) -> str:
        if request.condition == "less_than":
            return f"Values less than {request.threshold1}"
        elif request.condition == "greater_than":
            return f"Values greater than {request.threshold1}"
        elif request.condition == "equal_to":
            return f"Values equal to {request.threshold1}"
        elif request.condition == "between":
            t2 = request.threshold2 if request.threshold2 is not None else request.threshold1
            lo, hi = min(request.threshold1, t2), max(request.threshold1, t2)
            return f"Values between {lo} and {hi}"
        return request.condition

    def _describe_replacement(self, request: ConditionalReplacementRequest) -> str:
        if request.replacement_method == "specific_value":
            return f"with {request.replacement_value}"
        elif request.replacement_method == "weekday_mean":
            return "with mean of same weekday"
        elif request.replacement_method == "weekday_median":
            return "with median of same weekday"
        return request.replacement_method

    async def preview_conditional_replacement(
        self,
        dataset_id: str,
        request: ConditionalReplacementRequest,
        entity_id: Optional[str] = None,
        entity_column: Optional[str] = None
    ) -> ConditionalReplacementPreview:
        """Preview how many rows will be affected and weekday breakdown"""
        if entity_id:
            df = await self.get_entity_data(dataset_id, entity_id, entity_column)
        else:
            df = await self.get_dataset_dataframe(dataset_id)

        if df is None or request.column not in df.columns:
            return ConditionalReplacementPreview(
                affected_count=0,
                condition_text=self._describe_condition(request),
                replacement_text=self._describe_replacement(request),
                warnings=["Dataset or column not found"]
            )

        if not pd.api.types.is_numeric_dtype(df[request.column]):
            return ConditionalReplacementPreview(
                affected_count=0,
                condition_text=self._describe_condition(request),
                replacement_text=self._describe_replacement(request),
                warnings=[f"Column '{request.column}' is not numeric"]
            )

        mask = self._build_condition_mask(df[request.column], request)
        affected_count = int(mask.sum())

        weekday_breakdown = None
        warnings: List[str] = []

        date_col = self._detect_date_column(df)
        if request.replacement_method in ("weekday_mean", "weekday_median"):
            if not date_col:
                warnings.append("No date column detected — weekday replacement requires one")
            else:
                try:
                    dates = pd.to_datetime(df[date_col], errors='coerce')
                    affected_dates = dates[mask]
                    weekday_names = affected_dates.dt.day_name()
                    weekday_breakdown = weekday_names.value_counts().to_dict()

                    # Warn if weekday groups have < 3 non-matching observations per entity
                    entity_col = self._detect_entity_column(df)
                    non_matching = df[~mask]
                    if entity_col:
                        grouped = non_matching.groupby([entity_col, dates.dt.day_name()])[request.column].count()
                    else:
                        grouped = non_matching.groupby(dates.dt.day_name())[request.column].count()
                    if (grouped < 3).any():
                        warnings.append("Some weekday groups have fewer than 3 observations — replacement may fall back to original values")
                except Exception as e:
                    warnings.append(f"Weekday analysis failed: {e}")

        return ConditionalReplacementPreview(
            affected_count=affected_count,
            condition_text=self._describe_condition(request),
            replacement_text=self._describe_replacement(request),
            weekday_breakdown=weekday_breakdown,
            warnings=warnings
        )

    async def replace_values_conditional(
        self,
        dataset_id: str,
        request: ConditionalReplacementRequest,
        entity_id: Optional[str] = None,
        entity_column: Optional[str] = None
    ) -> PreprocessingResultResponse:
        """Conditional value replacement with optional weekday-based per-entity logic"""
        if entity_id:
            df = await self.get_entity_data(dataset_id, entity_id, entity_column)
        else:
            df = await self.get_dataset_dataframe(dataset_id)

        if df is None:
            return PreprocessingResultResponse(
                success=False, message="Dataset not found",
                rows_before=0, rows_after=0, rows_affected=0
            )

        rows_before = len(df)

        if request.column not in df.columns:
            return PreprocessingResultResponse(
                success=False, message=f"Column '{request.column}' not found",
                rows_before=rows_before, rows_after=rows_before, rows_affected=0
            )

        if not pd.api.types.is_numeric_dtype(df[request.column]):
            return PreprocessingResultResponse(
                success=False, message=f"Column '{request.column}' is not numeric",
                rows_before=rows_before, rows_after=rows_before, rows_affected=0
            )

        if request.replacement_method == "specific_value" and request.replacement_value is None:
            return PreprocessingResultResponse(
                success=False, message="replacement_value is required for specific_value method",
                rows_before=rows_before, rows_after=rows_before, rows_affected=0
            )

        try:
            col = request.column
            mask = self._build_condition_mask(df[col], request)
            affected_count = int(mask.sum())

            if affected_count == 0:
                return PreprocessingResultResponse(
                    success=True,
                    message="No values matched the condition",
                    rows_before=rows_before, rows_after=rows_before, rows_affected=0
                )

            if request.replacement_method == "specific_value":
                df.loc[mask, col] = request.replacement_value
            else:
                # weekday_mean or weekday_median — requires date column
                date_col = self._detect_date_column(df)
                if not date_col:
                    return PreprocessingResultResponse(
                        success=False,
                        message="No date column detected — weekday replacement requires one",
                        rows_before=rows_before, rows_after=rows_before, rows_affected=0
                    )

                # Parse dates and get weekday
                dates = pd.to_datetime(df[date_col], errors='coerce')
                df['_weekday'] = dates.dt.day_name()

                # Group by entity (if available) + weekday, compute on non-matching values only
                entity_col = None if entity_id else self._detect_entity_column(df)
                group_cols = [entity_col, '_weekday'] if entity_col else ['_weekday']

                non_matching = df[~mask]
                agg_func = 'mean' if request.replacement_method == 'weekday_mean' else 'median'
                # Compute replacement values per group from non-matching observations
                replacement_lookup = non_matching.groupby(group_cols)[col].agg(['count', agg_func])

                # Apply replacements only where we have >= 3 non-matching observations
                def _get_replacement(row):
                    key = tuple(row[g] for g in group_cols) if len(group_cols) > 1 else row[group_cols[0]]
                    if key in replacement_lookup.index:
                        lookup_row = replacement_lookup.loc[key]
                        if lookup_row['count'] >= 3:
                            return lookup_row[agg_func]
                    return row[col]  # fallback: keep original

                # Only apply to rows where mask is True
                rows_to_replace = df[mask].copy()
                new_values = rows_to_replace.apply(_get_replacement, axis=1)
                df.loc[mask, col] = new_values.values

                df = df.drop(columns=['_weekday'])

            await self.save_preprocessed_data(dataset_id, df, entity_id)

            return PreprocessingResultResponse(
                success=True,
                message=f"Replaced {affected_count} values in '{col}' {self._describe_replacement(request)}",
                rows_before=rows_before,
                rows_after=len(df),
                rows_affected=affected_count,
                preview_data=df.head(10).to_dict(orient='records')
            )
        except Exception as e:
            logger.error(f"Error in conditional replacement: {e}")
            # Clean up temp column if it exists
            if '_weekday' in df.columns:
                df = df.drop(columns=['_weekday'])
            return PreprocessingResultResponse(
                success=False, message=str(e),
                rows_before=rows_before, rows_after=rows_before, rows_affected=0
            )

    # ============================================
    # Reset & Download
    # ============================================

    async def reset_preprocessing(
        self,
        dataset_id: str,
        entity_id: Optional[str] = None
    ) -> bool:
        """Reset preprocessing by deleting cached preprocessed data"""
        try:
            redis = await get_redis()
            if redis is None:
                return False

            key = f"{REDIS_PREPROCESSED_PREFIX}{dataset_id}"
            if entity_id:
                key = f"{key}:{entity_id}"

            await redis.delete(key)
            return True
        except Exception as e:
            logger.error(f"Error resetting preprocessing: {e}")
            return False

    async def get_preprocessed_data(
        self,
        dataset_id: str,
        entity_id: Optional[str] = None,
        entity_column: Optional[str] = None,
        page: int = 1,
        page_size: int = 100
    ) -> Dict[str, Any]:
        """Get preprocessed data with pagination"""
        if entity_id:
            df = await self.get_entity_data(dataset_id, entity_id, entity_column)
        else:
            df = await self.get_dataset_dataframe(dataset_id)

        if df is None:
            return {"columns": [], "data": [], "total_rows": 0, "page": page, "page_size": page_size, "total_pages": 0}

        total_rows = len(df)
        total_pages = (total_rows + page_size - 1) // page_size

        start_idx = (page - 1) * page_size
        end_idx = start_idx + page_size
        page_data = df.iloc[start_idx:end_idx]

        return {
            "columns": df.columns.tolist(),
            "data": page_data.to_dict(orient='records'),
            "total_rows": total_rows,
            "page": page,
            "page_size": page_size,
            "total_pages": total_pages
        }

    # ============================================
    # Helper Methods
    # ============================================

    def _detect_entity_column(self, df: pd.DataFrame) -> Optional[str]:
        """Auto-detect entity column"""
        entity_keywords = ["entity", "product", "item", "sku", "category", "store", "location", "id"]

        for col in df.columns:
            col_lower = col.lower()
            if any(kw in col_lower for kw in entity_keywords):
                if df[col].dtype == 'object' or df[col].nunique() < len(df) * 0.5:
                    return col
        return None

    def _detect_date_column(self, df: pd.DataFrame) -> Optional[str]:
        """Auto-detect date column"""
        date_keywords = ["date", "time", "timestamp", "period", "day", "month", "year"]

        for col in df.columns:
            col_lower = col.lower()
            if any(kw in col_lower for kw in date_keywords):
                return col

            # Try parsing as date
            try:
                pd.to_datetime(df[col].iloc[:10], errors='raise')
                return col
            except Exception:
                continue

        return None
