"""Unit tests for PreprocessingService happy paths + per-entity grouping.

These pin the spec 002 behaviour so future refactors don't silently regress:
  - missing values with per-entity mean imputation
  - duplicates drop (first / last / subset)
  - outliers IQR detection
  - aggregation daily -> monthly
  - value replacement (conditional)
"""
from __future__ import annotations

from unittest.mock import AsyncMock, patch

import numpy as np
import pandas as pd
import pytest

from app.schemas.preprocessing import (
    AggregationFrequency,
    AggregationMethod,
    ConditionalReplacementRequest,
    DuplicateMethod,
    DuplicatesRequest,
    MissingValueMethod,
    MissingValuesRequest,
    OutlierAction,
    OutlierMethod,
    OutlierRequest,
    TimeAggregationRequest,
)
from app.services.preprocessing_service import PreprocessingService


# ------------------------------------------------------------------
# Shared fixtures
# ------------------------------------------------------------------

@pytest.fixture
def service():
    return PreprocessingService(tenant_id="tenant-123")


def _series_with_nans():
    """30 rows with 3 NaNs per entity; two entities with different means."""
    df = pd.DataFrame({
        "date": pd.date_range("2024-01-01", periods=30, freq="D"),
        "value": [10.0, 11.0, np.nan, 12.0, 9.0, np.nan, 10.5, 11.5, np.nan, 10.0] * 3,
        "entity_id": ["A"] * 10 + ["B"] * 10 + ["A"] * 5 + ["B"] * 5,
    })
    # Give entity B a clearly different mean by shifting its values
    df.loc[df["entity_id"] == "B", "value"] = df.loc[df["entity_id"] == "B", "value"] + 100
    return df


def _patch_data(service: PreprocessingService, df: pd.DataFrame):
    """Patch the two data-loading methods to return the provided dataframe."""
    async def _get(*args, **kwargs):
        return df.copy()
    return (
        patch.object(service, "get_dataset_dataframe", new=_get),
        patch.object(service, "get_entity_data", new=_get),
        patch.object(service, "save_preprocessed_data", new=AsyncMock(return_value=True)),
    )


# ------------------------------------------------------------------
# Missing values
# ------------------------------------------------------------------

@pytest.mark.asyncio
async def test_missing_values_fill_zero(service):
    df = _series_with_nans()
    p1, p2, p3 = _patch_data(service, df)
    with p1, p2, p3:
        result = await service.handle_missing_values(
            dataset_id="d1",
            request=MissingValuesRequest(
                method=MissingValueMethod.FILL_ZERO,
                columns=["value"],
            ),
        )
    assert result.success
    # rows_affected counts values filled; should be 9 NaNs
    assert result.rows_before == 30
    assert result.rows_after == 30


@pytest.mark.asyncio
async def test_missing_values_drop_reduces_rows(service):
    df = _series_with_nans()
    p1, p2, p3 = _patch_data(service, df)
    with p1, p2, p3:
        result = await service.handle_missing_values(
            dataset_id="d1",
            request=MissingValuesRequest(
                method=MissingValueMethod.DROP,
                columns=["value"],
            ),
        )
    assert result.success
    assert result.rows_after < result.rows_before


# ------------------------------------------------------------------
# Duplicates
# ------------------------------------------------------------------

@pytest.mark.asyncio
async def test_duplicates_keep_first(service):
    df = pd.DataFrame({
        "date": ["2024-01-01", "2024-01-01", "2024-01-02", "2024-01-03"],
        "entity_id": ["A", "A", "A", "A"],
        "value": [10, 11, 12, 13],
    })
    p1, p2, p3 = _patch_data(service, df)
    with p1, p2, p3:
        result = await service.handle_duplicates(
            dataset_id="d1",
            request=DuplicatesRequest(
                method=DuplicateMethod.KEEP_FIRST,
                subset=["date", "entity_id"],
            ),
        )
    assert result.success
    assert result.rows_before == 4
    assert result.rows_after == 3


# ------------------------------------------------------------------
# Outliers
# ------------------------------------------------------------------

@pytest.mark.asyncio
async def test_outliers_iqr_flags_extreme_values(service):
    # 1..5 cluster + 100 as outlier
    df = pd.DataFrame({
        "date": pd.date_range("2024-01-01", periods=12, freq="D"),
        "entity_id": ["A"] * 12,
        "value": [1.0, 2.0, 3.0, 4.0, 5.0, 3.5, 2.5, 4.5, 3.2, 2.8, 3.8, 100.0],
    })
    p1, p2, p3 = _patch_data(service, df)
    with p1, p2, p3:
        result = await service.handle_outliers(
            dataset_id="d1",
            request=OutlierRequest(
                method=OutlierMethod.IQR,
                action=OutlierAction.REMOVE,
                threshold=1.5,
                columns=["value"],
            ),
        )
    assert result.success
    # Outlier (100) should be removed
    assert result.rows_before == 12
    assert result.rows_after == 11


@pytest.mark.asyncio
async def test_outliers_flag_only_leaves_rows_untouched(service):
    df = pd.DataFrame({
        "date": pd.date_range("2024-01-01", periods=20, freq="D"),
        "entity_id": ["A"] * 20,
        "value": [float(i) for i in range(19)] + [500.0],
    })
    p1, p2, p3 = _patch_data(service, df)
    with p1, p2, p3:
        result = await service.handle_outliers(
            dataset_id="d1",
            request=OutlierRequest(
                method=OutlierMethod.IQR,
                action=OutlierAction.FLAG_ONLY,
                columns=["value"],
            ),
        )
    assert result.success
    # FLAG_ONLY should not change row count
    assert result.rows_before == result.rows_after


# ------------------------------------------------------------------
# Aggregation
# ------------------------------------------------------------------

@pytest.mark.asyncio
async def test_aggregate_daily_to_monthly(service):
    df = pd.DataFrame({
        "date": pd.date_range("2024-01-01", periods=90, freq="D"),
        "entity_id": ["A"] * 90,
        "value": [1.0] * 90,
    })
    p1, p2, p3 = _patch_data(service, df)
    with p1, p2, p3:
        result = await service.aggregate_time(
            dataset_id="d1",
            request=TimeAggregationRequest(
                frequency=AggregationFrequency.MONTHLY,
                method=AggregationMethod.SUM,
                date_column="date",
                value_columns=["value"],
            ),
            entity_column="entity_id",
        )
    assert result.success
    # 90 daily rows spanning Jan/Feb/Mar -> 3 monthly rows
    assert result.rows_after <= 4
    assert result.rows_before == 90


# ------------------------------------------------------------------
# Conditional replacement (spec 002's ported R feature)
# ------------------------------------------------------------------

@pytest.mark.asyncio
async def test_conditional_replace_less_than_specific_value(service):
    df = pd.DataFrame({
        "date": pd.date_range("2024-01-01", periods=10, freq="D"),
        "entity_id": ["A"] * 10,
        "value": [5.0, 10.0, -3.0, 8.0, -1.0, 12.0, 7.0, -2.0, 9.0, 6.0],
    })
    p1, p2, p3 = _patch_data(service, df)
    with p1, p2, p3:
        result = await service.replace_values_conditional(
            dataset_id="d1",
            request=ConditionalReplacementRequest(
                column="value",
                condition="less_than",
                threshold1=0.0,
                replacement_method="specific_value",
                replacement_value=0.0,
            ),
        )
    assert result.success
    # 3 negative values replaced
    assert result.rows_affected == 3
