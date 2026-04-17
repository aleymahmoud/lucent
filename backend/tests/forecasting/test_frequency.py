"""Tests for frequency detection."""
import pandas as pd
import pytest

from app.forecasting.frequency import detect_frequency, irregular_intervals_pct


def _dates(start: str, periods: int, freq: str) -> pd.DatetimeIndex:
    return pd.date_range(start=start, periods=periods, freq=freq)


def test_detect_daily():
    dates = _dates("2024-01-01", 90, "D")
    code, period, median = detect_frequency(dates)
    assert code == "D"
    assert period == 7
    assert 0.9 <= median <= 1.1


def test_detect_weekly():
    dates = _dates("2024-01-01", 52, "7D")
    code, period, median = detect_frequency(dates)
    assert code == "W"
    assert period == 52
    assert 6.5 <= median <= 7.5


def test_detect_monthly():
    dates = _dates("2024-01-01", 24, "MS")
    code, period, median = detect_frequency(dates)
    assert code == "M"
    assert period == 12


def test_detect_quarterly():
    dates = _dates("2024-01-01", 12, "QS")
    code, period, median = detect_frequency(dates)
    assert code == "Q"
    assert period == 4


def test_detect_yearly():
    dates = _dates("2020-01-01", 5, "YS")
    code, period, median = detect_frequency(dates)
    assert code == "Y"
    assert period == 1


def test_empty_index_defaults_daily():
    dates = pd.DatetimeIndex([])
    code, period, median = detect_frequency(dates)
    assert code == "D"
    assert period == 7


def test_single_row_defaults_daily():
    dates = pd.DatetimeIndex([pd.Timestamp("2024-01-01")])
    code, period, median = detect_frequency(dates)
    assert code == "D"


def test_unbucketed_fallback_to_daily():
    # 3-day intervals fall in no bucket
    dates = _dates("2024-01-01", 10, "3D")
    code, period, median = detect_frequency(dates)
    assert code == "D"  # fallback
    assert median == pytest.approx(3.0, abs=0.1)


def test_irregular_intervals_clean():
    dates = _dates("2024-01-01", 30, "D")
    assert irregular_intervals_pct(dates) == 0.0


def test_irregular_intervals_with_gaps():
    # Mostly 1-day spacing with a few much-larger gaps
    dates = pd.DatetimeIndex([
        pd.Timestamp("2024-01-01"),
        pd.Timestamp("2024-01-02"),
        pd.Timestamp("2024-01-03"),
        pd.Timestamp("2024-01-10"),  # 7-day gap
        pd.Timestamp("2024-01-11"),
        pd.Timestamp("2024-01-12"),
        pd.Timestamp("2024-01-20"),  # 8-day gap
    ])
    pct = irregular_intervals_pct(dates, tolerance=0.5)
    assert pct > 0
