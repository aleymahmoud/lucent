"""Prophet forecaster tests — skipped when CmdStan is not available."""
from __future__ import annotations

import numpy as np
import pytest

from tests.data.synthetic import daily_weekly_seasonal


def _cmdstan_available() -> bool:
    try:
        import cmdstanpy  # noqa: F401
        cmdstanpy.cmdstan_path()
        return True
    except Exception:
        return False


pytestmark = pytest.mark.skipif(
    not _cmdstan_available(), reason="CmdStan not installed"
)


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


def test_prophet_fit_and_predict():
    from app.forecasting.prophet_forecaster import ProphetForecaster

    series = daily_weekly_seasonal(n=120)
    forecaster = ProphetForecaster(
        frequency="D",
        yearly_seasonality=False,    # dataset too short
        weekly_seasonality=True,
        daily_seasonality=False,
    )
    forecaster.fit(series)
    assert forecaster.is_fitted

    output = forecaster.predict(horizon=7)
    _assert_predictions_ok(output, horizon=7)

    for key in ("mae", "rmse", "mape"):
        assert key in output.metrics
        assert np.isfinite(output.metrics[key])


def test_prophet_residuals_returned():
    from app.forecasting.prophet_forecaster import ProphetForecaster

    series = daily_weekly_seasonal(n=120)
    forecaster = ProphetForecaster(
        frequency="D",
        yearly_seasonality=False,
        weekly_seasonality=True,
        daily_seasonality=False,
    )
    forecaster.fit(series)
    output = forecaster.predict(horizon=5)
    assert output.residuals is not None
    assert len(output.residuals) >= 50
