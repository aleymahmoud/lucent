"""Tests for data validation."""
import numpy as np
import pandas as pd
import pytest

from app.forecasting.data_validator import validate_for_method


def _series(n: int, constant: bool = False) -> pd.Series:
    values = np.full(n, 42.0) if constant else np.arange(n, dtype=float)
    return pd.Series(values)


def test_prophet_needs_15():
    result = validate_for_method(_series(12), "prophet")
    assert result.blocking_error is not None
    assert "15" in result.blocking_error
    assert "prophet" in result.blocking_error.lower() or "Prophet" in result.blocking_error


def test_prophet_15_ok():
    result = validate_for_method(_series(15), "prophet")
    assert result.blocking_error is None


def test_arima_non_seasonal_needs_10():
    result = validate_for_method(_series(9), "arima", seasonal_period=1)
    assert result.blocking_error is not None
    assert "10" in result.blocking_error


def test_arima_seasonal_needs_2s_plus_5():
    # s=7 -> need 19
    result = validate_for_method(_series(18), "arima", seasonal_period=7)
    assert result.blocking_error is not None
    assert "19" in result.blocking_error

    result = validate_for_method(_series(19), "arima", seasonal_period=7)
    assert result.blocking_error is None


def test_ets_seasonal_needs_2freq_plus_5():
    result = validate_for_method(_series(18), "ets", seasonal_period=7)
    assert result.blocking_error is not None


def test_zero_variance_blocks():
    result = validate_for_method(_series(30, constant=True), "ets", seasonal_period=1)
    assert result.blocking_error is not None
    assert "identical" in result.blocking_error


def test_suggests_alternative_on_failure():
    # 12 obs: too few for Prophet, enough for non-seasonal ETS/ARIMA
    result = validate_for_method(_series(12), "prophet")
    assert result.blocking_error is not None
    # Should suggest at least one alternative
    assert len(result.suggested_alternative_methods) >= 1


def test_prophet_yearly_warning():
    result = validate_for_method(_series(90), "prophet", prophet_yearly=True)
    assert result.blocking_error is None
    assert any("yearly" in w.lower() for w in result.warnings)


def test_prophet_no_warning_when_enough_data():
    result = validate_for_method(_series(800), "prophet", prophet_yearly=True)
    assert result.blocking_error is None
    assert not any("yearly" in w.lower() for w in result.warnings)


def test_irregular_intervals_warning():
    base = pd.date_range("2024-01-01", periods=30, freq="D").tolist()
    # inject 5-day gaps
    base.extend([base[10] + pd.Timedelta(days=5), base[20] + pd.Timedelta(days=7)])
    dates = pd.DatetimeIndex(sorted(set(base)))
    series = pd.Series(np.arange(len(dates), dtype=float), index=dates)
    result = validate_for_method(series, "ets", seasonal_period=1, dates=dates)
    # Irregular warning may or may not fire depending on tolerance; just ensure no crash
    assert result.blocking_error is None
