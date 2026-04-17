"""
Synthetic dataset generators for tests and benchmarks.

All generators are deterministic given the same seed. Intended to cover
a variety of time-series shapes without depending on external data.
"""
from __future__ import annotations

from typing import Tuple

import numpy as np
import pandas as pd


def daily_weekly_seasonal(
    n: int = 120,
    start: str = "2024-01-01",
    trend_slope: float = 0.3,
    seasonal_amplitude: float = 8.0,
    noise_scale: float = 1.0,
    seed: int = 42,
) -> pd.Series:
    """
    Daily series with a linear trend and weekly (period=7) seasonal cycle.
    Long enough to exercise seasonal ARIMA and ETS.
    """
    rng = np.random.default_rng(seed)
    t = np.arange(n)
    trend = 100.0 + trend_slope * t
    seasonal = seasonal_amplitude * np.sin(2 * np.pi * t / 7)
    noise = rng.standard_normal(n) * noise_scale
    values = trend + seasonal + noise
    index = pd.date_range(start=start, periods=n, freq="D")
    return pd.Series(values, index=index, name="value")


def monthly_yearly_seasonal(
    n: int = 36,
    start: str = "2022-01-01",
    trend_slope: float = 2.0,
    seasonal_amplitude: float = 40.0,
    noise_scale: float = 3.0,
    seed: int = 43,
) -> pd.Series:
    """Monthly series with a linear trend and yearly (period=12) seasonal cycle."""
    rng = np.random.default_rng(seed)
    t = np.arange(n)
    trend = 500.0 + trend_slope * t
    seasonal = seasonal_amplitude * np.sin(2 * np.pi * t / 12)
    noise = rng.standard_normal(n) * noise_scale
    values = trend + seasonal + noise
    index = pd.date_range(start=start, periods=n, freq="MS")
    return pd.Series(values, index=index, name="value")


def pure_trend(
    n: int = 60,
    start: str = "2024-01-01",
    slope: float = 0.5,
    noise_scale: float = 0.5,
    seed: int = 44,
) -> pd.Series:
    """Linear trend plus small noise; no seasonality."""
    rng = np.random.default_rng(seed)
    t = np.arange(n)
    values = 50.0 + slope * t + rng.standard_normal(n) * noise_scale
    index = pd.date_range(start=start, periods=n, freq="D")
    return pd.Series(values, index=index, name="value")


def random_walk(
    n: int = 80,
    start: str = "2024-01-01",
    step_scale: float = 1.0,
    seed: int = 45,
) -> pd.Series:
    """Non-stationary random walk (integrated series)."""
    rng = np.random.default_rng(seed)
    steps = rng.standard_normal(n) * step_scale
    values = np.cumsum(steps) + 20.0
    index = pd.date_range(start=start, periods=n, freq="D")
    return pd.Series(values, index=index, name="value")


def with_outliers(
    base: pd.Series,
    outlier_indices: Tuple[int, ...] = (15, 42),
    magnitude: float = 10.0,
) -> pd.Series:
    """Inject large positive outliers at given positions of an existing series."""
    s = base.copy()
    arr = s.to_numpy()
    mean_val = float(np.mean(arr))
    for i in outlier_indices:
        if 0 <= i < len(arr):
            arr[i] = mean_val + magnitude * float(np.std(arr))
    s[:] = arr
    return s


def make_benchmark_suite() -> dict[str, pd.Series]:
    """
    Return 20 named synthetic series used by the benchmark runner.

    Naming convention: <shape>_<variant>_<length>.
    """
    datasets: dict[str, pd.Series] = {}
    # Daily weekly-seasonal at multiple lengths and noise levels
    datasets["daily_ws_120_lo"] = daily_weekly_seasonal(n=120, noise_scale=0.5, seed=1)
    datasets["daily_ws_120_hi"] = daily_weekly_seasonal(n=120, noise_scale=3.0, seed=2)
    datasets["daily_ws_60"] = daily_weekly_seasonal(n=60, seed=3)
    datasets["daily_ws_365"] = daily_weekly_seasonal(n=365, seed=4)
    datasets["daily_ws_30"] = daily_weekly_seasonal(n=30, seed=5)

    # Daily pure trend
    datasets["daily_trend_100"] = pure_trend(n=100, seed=6)
    datasets["daily_trend_30"] = pure_trend(n=30, seed=7)

    # Daily random walk
    datasets["daily_rw_100"] = random_walk(n=100, seed=8)
    datasets["daily_rw_200"] = random_walk(n=200, seed=9)

    # Daily with outliers
    datasets["daily_ws_with_outliers"] = with_outliers(
        daily_weekly_seasonal(n=120, seed=10)
    )

    # Monthly yearly-seasonal
    datasets["monthly_ys_36"] = monthly_yearly_seasonal(n=36, seed=11)
    datasets["monthly_ys_48"] = monthly_yearly_seasonal(n=48, seed=12)
    datasets["monthly_ys_24"] = monthly_yearly_seasonal(n=24, seed=13)

    # Monthly trend-only
    datasets["monthly_trend_36"] = pure_trend(n=36, slope=1.0, noise_scale=1.0, seed=14).asfreq("MS").fillna(method="ffill")

    # Larger daily datasets
    datasets["daily_ws_730"] = daily_weekly_seasonal(n=730, seed=15)
    datasets["daily_ws_500_noisy"] = daily_weekly_seasonal(n=500, noise_scale=5.0, seed=16)

    # Flat + small noise
    rng = np.random.default_rng(17)
    flat_vals = 100.0 + rng.standard_normal(90) * 0.1
    datasets["daily_flat_90"] = pd.Series(
        flat_vals, index=pd.date_range("2024-01-01", periods=90, freq="D")
    )

    # Exponential-ish growth
    datasets["daily_exp_100"] = pd.Series(
        np.exp(np.linspace(4.5, 5.5, 100)) + np.random.default_rng(18).standard_normal(100),
        index=pd.date_range("2024-01-01", periods=100, freq="D"),
    )

    # Daily weekly-seasonal with downward trend
    datasets["daily_ws_dn_120"] = daily_weekly_seasonal(n=120, trend_slope=-0.4, seed=19)

    # Minimal viable series (just enough for non-seasonal ARIMA/ETS)
    datasets["daily_min_15"] = daily_weekly_seasonal(n=15, noise_scale=0.3, seed=20)

    return datasets
