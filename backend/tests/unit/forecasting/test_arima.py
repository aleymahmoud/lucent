"""ARIMA forecaster happy-path + fallback tests."""
from __future__ import annotations

from unittest.mock import patch

import numpy as np
import pandas as pd
import pytest

from app.forecasting.arima import ARIMAForecaster
from tests.data.synthetic import daily_weekly_seasonal, random_walk


def _assert_predictions_ok(output, horizon: int):
    """Shared shape + sanity checks."""
    df = output.predictions
    assert len(df) == horizon
    assert set(df.columns) >= {"date", "value", "lower_bound", "upper_bound"}
    values = df["value"].to_numpy()
    lower = df["lower_bound"].to_numpy()
    upper = df["upper_bound"].to_numpy()
    assert np.all(np.isfinite(values)), "forecast values must be finite"
    assert np.all(np.isfinite(lower)) and np.all(np.isfinite(upper))
    assert np.all(lower <= values + 1e-6), "lower bound must be <= value"
    assert np.all(values <= upper + 1e-6), "value must be <= upper bound"


def test_arima_auto_fit_daily_weekly_seasonal():
    series = daily_weekly_seasonal(n=120)
    forecaster = ARIMAForecaster(frequency="D", auto=True)
    forecaster.fit(series)
    assert forecaster.is_fitted
    assert forecaster.fallback_level == 0

    output = forecaster.predict(horizon=14)
    _assert_predictions_ok(output, horizon=14)

    # in-sample metrics present and finite
    for key in ("mae", "rmse", "mape"):
        assert key in output.metrics
        assert np.isfinite(output.metrics[key])

    # model_summary surface
    assert output.model_summary["method"] == "ARIMA"
    assert "order" in output.model_summary
    # Coefficient list shape introduced in spec 002
    coeffs = output.model_summary.get("coefficients")
    assert isinstance(coeffs, list) and len(coeffs) > 0
    first = coeffs[0]
    assert "name" in first and "estimate" in first


def test_arima_auto_fit_random_walk():
    """Random walk is non-stationary — differencing should kick in."""
    series = random_walk(n=80)
    forecaster = ARIMAForecaster(frequency="D", auto=True)
    forecaster.fit(series)
    output = forecaster.predict(horizon=10)
    _assert_predictions_ok(output, horizon=10)


def test_arima_residuals_returned():
    series = daily_weekly_seasonal(n=100)
    forecaster = ARIMAForecaster(frequency="D", auto=True)
    forecaster.fit(series)
    output = forecaster.predict(horizon=7)
    assert output.residuals is not None
    assert len(output.residuals) >= 50  # should roughly equal training size


def test_arima_fallback_chain_advances_when_primary_fails():
    """If the primary fit raises, fallback_level must advance."""
    series = daily_weekly_seasonal(n=100)
    forecaster = ARIMAForecaster(frequency="D", auto=True)

    # Force the first _try_fit call to return False — primary fails
    original = forecaster._try_fit
    call_count = {"n": 0}

    def _patched(y, order, seasonal_order):
        call_count["n"] += 1
        # First call = primary (fail); subsequent calls use real implementation
        if call_count["n"] == 1:
            return False
        return original(y, order, seasonal_order)

    forecaster._try_fit = _patched  # type: ignore[assignment]
    forecaster.fit(series)
    assert forecaster.is_fitted
    assert forecaster.fallback_level >= 1  # at least level 1 (simpler grid)


def test_arima_manual_order():
    series = daily_weekly_seasonal(n=100)
    forecaster = ARIMAForecaster(frequency="D", order=(1, 1, 1), auto=False)
    forecaster.fit(series)
    assert forecaster.order == (1, 1, 1)
    output = forecaster.predict(horizon=5)
    _assert_predictions_ok(output, horizon=5)
