"""Tests for cross-validation engine."""
from dataclasses import dataclass

import numpy as np
import pandas as pd
import pytest

from app.forecasting.cross_validation import _plan_folds, run_cv
from app.forecasting.base import BaseForecaster, ForecastOutput


class _DummyForecaster(BaseForecaster):
    """Naive forecaster: predicts the last observed value for all future periods."""

    def __init__(self):
        super().__init__(frequency="D", confidence_level=0.95)
        self._last = None

    def fit(self, y, exog=None):
        self._last = float(y.iloc[-1])
        self.is_fitted = True
        self._training_data = y

    def predict(self, horizon, exog=None) -> ForecastOutput:
        dates = pd.date_range(self._training_data.index[-1] + pd.Timedelta(days=1), periods=horizon, freq="D")
        predictions = pd.DataFrame(
            {"date": dates, "value": [self._last] * horizon, "lower_bound": [self._last] * horizon, "upper_bound": [self._last] * horizon}
        )
        return ForecastOutput(predictions=predictions, metrics={}, model_summary={})

    def get_params(self):
        return {}

    @classmethod
    def auto_detect_params(cls, y, frequency="D"):
        return {}


def _series(n: int) -> pd.Series:
    return pd.Series(
        np.arange(n, dtype=float),
        index=pd.date_range("2024-01-01", periods=n, freq="D"),
    )


def test_plan_folds_ok():
    initial_train, step, folds, reduced = _plan_folds(n=100, folds=3, horizon=10, initial_train_ratio=0.7)
    assert initial_train > 0
    assert step > 0
    assert folds >= 1
    # 70 + 2*5 + 10 = 90 <= 100, so not reduced
    assert reduced is False


def test_plan_folds_reduced_when_too_short():
    initial_train, step, folds, reduced = _plan_folds(n=30, folds=5, horizon=10, initial_train_ratio=0.7)
    # 21 + 4*5 + 10 = 51 > 30 -> must reduce
    assert reduced is True
    assert folds < 5


def test_rolling_cv_runs():
    series = _series(100)
    result = run_cv(
        series,
        forecaster_factory=_DummyForecaster,
        folds=3,
        method="rolling",
        initial_train_size=0.7,
        horizon=10,
    )
    assert len(result.folds) >= 1
    assert result.method == "rolling"
    # Each fold's train_size should equal initial_train (rolling is fixed-size window)
    sizes = {f.train_size for f in result.folds}
    assert len(sizes) == 1


def test_expanding_cv_grows_train():
    series = _series(100)
    result = run_cv(
        series,
        forecaster_factory=_DummyForecaster,
        folds=3,
        method="expanding",
        initial_train_size=0.7,
        horizon=10,
    )
    assert len(result.folds) >= 2
    # Train size should grow across folds
    sizes = [f.train_size for f in result.folds]
    assert sizes == sorted(sizes)
    assert sizes[0] < sizes[-1]


def test_cv_computes_averages():
    series = _series(100)
    result = run_cv(
        series,
        forecaster_factory=_DummyForecaster,
        folds=3,
        method="rolling",
        initial_train_size=0.7,
        horizon=10,
    )
    assert np.isfinite(result.average_mae)
    assert np.isfinite(result.average_rmse)


def test_cv_reduces_folds_for_small_data():
    series = _series(30)
    result = run_cv(
        series,
        forecaster_factory=_DummyForecaster,
        folds=5,
        method="rolling",
        initial_train_size=0.7,
        horizon=10,
    )
    assert result.reduced_folds is True
    assert result.requested_folds == 5
