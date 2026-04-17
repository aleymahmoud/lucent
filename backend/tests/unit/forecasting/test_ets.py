"""ETS forecaster happy-path tests."""
from __future__ import annotations

import numpy as np

from app.forecasting.ets import ETSForecaster
from tests.data.synthetic import daily_weekly_seasonal, pure_trend


def _assert_predictions_ok(output, horizon: int):
    df = output.predictions
    assert len(df) == horizon
    values = df["value"].to_numpy()
    lower = df["lower_bound"].to_numpy()
    upper = df["upper_bound"].to_numpy()
    assert np.all(np.isfinite(values))
    assert np.all(np.isfinite(lower)) and np.all(np.isfinite(upper))
    assert np.all(lower <= values + 1e-6)
    assert np.all(values <= upper + 1e-6)


def test_ets_auto_fit_daily_weekly():
    series = daily_weekly_seasonal(n=120)
    forecaster = ETSForecaster(frequency="D", auto=True)
    forecaster.fit(series)
    assert forecaster.is_fitted

    output = forecaster.predict(horizon=14)
    _assert_predictions_ok(output, horizon=14)

    for key in ("mae", "rmse", "mape"):
        assert key in output.metrics
        assert np.isfinite(output.metrics[key])


def test_ets_auto_fit_pure_trend():
    """Series without seasonality — ETS should still produce a valid forecast."""
    series = pure_trend(n=60)
    forecaster = ETSForecaster(frequency="D", auto=True)
    forecaster.fit(series)
    output = forecaster.predict(horizon=7)
    _assert_predictions_ok(output, horizon=7)


def test_ets_residuals_returned():
    series = daily_weekly_seasonal(n=100)
    forecaster = ETSForecaster(frequency="D", auto=True)
    forecaster.fit(series)
    output = forecaster.predict(horizon=5)
    assert output.residuals is not None
    assert len(output.residuals) >= 50


def test_ets_manual_trend_only():
    series = pure_trend(n=50)
    forecaster = ETSForecaster(
        frequency="D", auto=False, trend="add", seasonal=None, damped_trend=False
    )
    forecaster.fit(series)
    output = forecaster.predict(horizon=5)
    _assert_predictions_ok(output, horizon=5)


def test_ets_coefficients_in_model_summary():
    series = daily_weekly_seasonal(n=120)
    forecaster = ETSForecaster(frequency="D", auto=True)
    forecaster.fit(series)
    output = forecaster.predict(horizon=5)
    coeffs = output.model_summary.get("coefficients")
    # spec 002 introduced list-of-dict shape; ETS may have SE unavailable
    assert coeffs is None or isinstance(coeffs, list)
    if isinstance(coeffs, list) and len(coeffs) > 0:
        assert "name" in coeffs[0] and "estimate" in coeffs[0]
