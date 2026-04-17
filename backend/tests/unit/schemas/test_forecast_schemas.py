"""Contract tests: residuals must survive serialization + be read correctly."""
from __future__ import annotations

import json
from datetime import datetime
from unittest.mock import AsyncMock, patch

import pytest

from app.schemas.forecast import (
    ForecastMethod,
    ForecastResultResponse,
    ForecastStatus,
    ModelSummaryResponse,
)
from app.services.diagnostics_service import DiagnosticsService


def _build_result(residuals):
    """Build a minimal ForecastResultResponse with a controllable residuals field."""
    return ForecastResultResponse(
        id="forecast-1",
        dataset_id="dataset-1",
        entity_id="entity-A",
        method=ForecastMethod.ARIMA,
        status=ForecastStatus.COMPLETED,
        progress=100,
        predictions=[],
        metrics=None,
        model_summary=ModelSummaryResponse(
            method="ARIMA",
            parameters={"p": 1, "d": 1, "q": 1},
            coefficients=None,
            diagnostics={"residual_mean": 0.01, "residual_std": 1.0},
            regressors_used=None,
            residuals=residuals,
        ),
        cv_results=None,
        detected_frequency="D",
        detected_seasonal_period=7,
        warnings=[],
        created_at=datetime.utcnow(),
    )


def test_residuals_survive_json_roundtrip():
    residuals = [0.1, -0.2, 0.3, -0.05, 0.12, -0.08, 0.02] * 10  # 70 values
    result = _build_result(residuals)

    # serialize the way forecast_service does for Redis
    as_json = json.dumps(result.model_dump(mode="json"), default=str)

    # deserialize back
    rehydrated = ForecastResultResponse(**json.loads(as_json))

    assert rehydrated.model_summary is not None
    recovered = rehydrated.model_summary.residuals
    assert recovered is not None
    assert len(recovered) == len(residuals)
    for a, b in zip(residuals, recovered):
        assert abs(a - b) < 1e-6


def test_extract_residuals_uses_stored_array():
    """DiagnosticsService should read from model_summary.residuals directly."""
    residuals = [float(i) * 0.1 for i in range(30)]
    result = _build_result(residuals)

    service = DiagnosticsService(tenant_id="tenant-123")
    out = service._extract_residuals(result)

    assert out is not None
    assert len(out) == len(residuals)


def test_extract_residuals_returns_none_for_legacy_record():
    """Legacy record = no residuals in model_summary; must NOT synthesize."""
    result = _build_result(residuals=None)

    service = DiagnosticsService(tenant_id="tenant-123")
    out = service._extract_residuals(result)

    assert out is None  # not synthetic data — None signals "legacy"


def test_extract_residuals_reads_legacy_diagnostics_location():
    """
    Backward compat: diagnostics["residuals"] used to hold the array in
    some early records — the extractor should still find it.
    """
    result = _build_result(residuals=None)
    # emulate legacy shape
    result.model_summary.diagnostics["residuals"] = [0.1, 0.2, -0.3, 0.05, 0.01]

    service = DiagnosticsService(tenant_id="tenant-123")
    out = service._extract_residuals(result)

    assert out is not None
    assert len(out) == 5


def test_extract_residuals_rejects_too_short_array():
    """Arrays with < 4 values should be treated as unusable."""
    result = _build_result(residuals=[0.1, -0.1])  # only 2 values

    service = DiagnosticsService(tenant_id="tenant-123")
    out = service._extract_residuals(result)

    assert out is None
