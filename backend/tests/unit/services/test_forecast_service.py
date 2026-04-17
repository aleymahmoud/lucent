"""End-to-end test of ForecastService.run_forecast with mocked data layer."""
from __future__ import annotations

import json
from unittest.mock import AsyncMock, patch

import numpy as np
import pandas as pd
import pytest

from app.schemas.forecast import (
    ForecastFrequency,
    ForecastMethod,
    ForecastRequest,
    ForecastStatus,
    CrossValidationRequest,
)
from app.services.forecast_service import ForecastService
from tests.data.synthetic import daily_weekly_seasonal


@pytest.fixture
def synthetic_dataset():
    """A dataframe with date, value, entity_id columns covering 120 days."""
    series = daily_weekly_seasonal(n=120)
    df = pd.DataFrame({
        "date": series.index,
        "value": series.values,
        "entity_id": "ENTITY_A",
    })
    return df


@pytest.fixture
def stub_preprocessing_service(synthetic_dataset):
    """Replace PreprocessingService methods on the forecast service."""
    async def _get_df(dataset_id: str):
        return synthetic_dataset.copy()

    async def _get_entity(dataset_id: str, entity_id: str, entity_column=None):
        df = synthetic_dataset.copy()
        return df  # single entity in synthetic data

    return _get_df, _get_entity


@pytest.fixture
def stub_redis():
    """Minimal async fake that swallows set/get without errors."""
    class _FakeRedis:
        def __init__(self):
            self.store: dict[str, str] = {}

        async def set(self, key, value, ex=None):
            self.store[key] = value

        async def get(self, key):
            return self.store.get(key)

        async def delete(self, key):
            self.store.pop(key, None)

    return _FakeRedis()


@pytest.mark.asyncio
async def test_run_forecast_arima_happy_path(synthetic_dataset, stub_preprocessing_service, stub_redis):
    get_df, get_entity = stub_preprocessing_service

    service = ForecastService(tenant_id="tenant-123")

    with patch.object(service.preprocessing_service, "get_dataset_dataframe", new=get_df), \
         patch.object(service.preprocessing_service, "get_entity_data", new=get_entity), \
         patch("app.services.forecast_service.get_redis", return_value=stub_redis):
        request = ForecastRequest(
            dataset_id="dataset-1",
            entity_id="ENTITY_A",
            method=ForecastMethod.ARIMA,
            horizon=7,
            frequency=ForecastFrequency.DAILY,
            frequency_auto_detect=True,
            confidence_level=0.95,
        )
        result = await service.run_forecast(request)

    assert result.status == ForecastStatus.COMPLETED
    assert len(result.predictions) == 7
    assert result.metrics is not None
    assert np.isfinite(result.metrics.mae)

    # Frequency auto-detection populated
    assert result.detected_frequency == "D"
    assert result.detected_seasonal_period == 7

    # Forecast statistics populated
    assert result.forecast_statistics is not None
    assert np.isfinite(result.forecast_statistics.mean)

    # Residuals persisted for diagnostics
    assert result.model_summary is not None
    assert result.model_summary.residuals is not None
    assert len(result.model_summary.residuals) > 0


@pytest.mark.asyncio
async def test_run_forecast_with_cv_populates_cv_results(
    synthetic_dataset, stub_preprocessing_service, stub_redis
):
    get_df, get_entity = stub_preprocessing_service
    service = ForecastService(tenant_id="tenant-123")

    with patch.object(service.preprocessing_service, "get_dataset_dataframe", new=get_df), \
         patch.object(service.preprocessing_service, "get_entity_data", new=get_entity), \
         patch("app.services.forecast_service.get_redis", return_value=stub_redis):
        request = ForecastRequest(
            dataset_id="dataset-1",
            entity_id="ENTITY_A",
            method=ForecastMethod.ETS,   # faster than ARIMA
            horizon=7,
            frequency=ForecastFrequency.DAILY,
            frequency_auto_detect=True,
            confidence_level=0.95,
            cross_validation=CrossValidationRequest(
                enabled=True,
                folds=2,
                method="rolling",
                initial_train_size=0.7,
            ),
        )
        result = await service.run_forecast(request)

    assert result.status == ForecastStatus.COMPLETED
    assert result.cv_results is not None
    assert result.cv_results.folds >= 1
    assert np.isfinite(result.cv_results.average_metrics.mae)


@pytest.mark.asyncio
async def test_run_forecast_blocks_insufficient_data(stub_redis):
    """Dataset with only 6 rows should be rejected up-front by the validator."""
    tiny = pd.DataFrame({
        "date": pd.date_range("2024-01-01", periods=6, freq="D"),
        "value": [10.0, 11.0, 9.5, 12.0, 10.5, 11.2],
        "entity_id": "A",
    })

    async def _get_df(_):
        return tiny

    async def _get_entity(*args, **kwargs):
        return tiny

    service = ForecastService(tenant_id="tenant-123")
    with patch.object(service.preprocessing_service, "get_dataset_dataframe", new=_get_df), \
         patch.object(service.preprocessing_service, "get_entity_data", new=_get_entity), \
         patch("app.services.forecast_service.get_redis", return_value=stub_redis):
        request = ForecastRequest(
            dataset_id="dataset-1",
            entity_id="A",
            method=ForecastMethod.ARIMA,
            horizon=5,
            frequency=ForecastFrequency.DAILY,
            frequency_auto_detect=True,
            confidence_level=0.95,
        )
        result = await service.run_forecast(request)

    assert result.status == ForecastStatus.FAILED
    assert "observations" in (result.error or "") or "Insufficient" in (result.error or "")
