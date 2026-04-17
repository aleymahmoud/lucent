"""
Time series frequency detection.

Ports the detection logic from the old R app's `detect_frequency()` function.
"""
from __future__ import annotations

from typing import Tuple

import pandas as pd


FREQUENCY_BUCKETS = [
    # (min_days, max_days, freq_code, seasonal_period)
    (0.5, 1.5, "D", 7),       # daily -> weekly seasonal
    (6.0, 9.0, "W", 52),      # weekly -> yearly seasonal
    (28.0, 31.0, "M", 12),    # monthly -> yearly seasonal
    (85.0, 94.0, "Q", 4),     # quarterly -> yearly seasonal
    (360.0, 370.0, "Y", 1),   # yearly -> no further seasonality
]


def detect_frequency(dates: pd.DatetimeIndex) -> Tuple[str, int, float]:
    """Detect time series frequency from a DatetimeIndex.

    Returns:
        (freq_code, seasonal_period, median_interval_days)
        freq_code is one of "D", "W", "M", "Q", "Y"
        seasonal_period is the period length in units of freq_code
        median_interval_days is the raw measurement for diagnostics
    """
    if dates is None or len(dates) < 2:
        return "D", 7, 1.0

    diffs_days = (
        dates.to_series()
        .sort_values()
        .diff()
        .dropna()
        .dt.total_seconds()
        / 86400.0
    )

    if len(diffs_days) == 0:
        return "D", 7, 1.0

    median = float(diffs_days.median())

    for min_days, max_days, freq, period in FREQUENCY_BUCKETS:
        if min_days <= median <= max_days:
            return freq, period, median

    # Fallback: couldn't bucket — treat as daily by default
    return "D", 7, median


def irregular_intervals_pct(dates: pd.DatetimeIndex, tolerance: float = 0.5) -> float:
    """Percentage of consecutive intervals that deviate from the median by > tolerance.

    Used to detect datasets with significant gaps that would benefit from resampling.
    """
    if dates is None or len(dates) < 3:
        return 0.0

    diffs_days = (
        dates.to_series()
        .sort_values()
        .diff()
        .dropna()
        .dt.total_seconds()
        / 86400.0
    )

    if len(diffs_days) == 0:
        return 0.0

    median = float(diffs_days.median())
    if median <= 0:
        return 0.0

    deviation = (diffs_days - median).abs() / median
    return float((deviation > tolerance).sum() / len(deviation) * 100.0)
