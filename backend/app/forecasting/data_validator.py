"""
Pre-flight data validation for forecasting.

Enforces per-method minimum-observation rules, detects zero-variance series,
and emits warnings for detectable misconfigurations.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import List, Optional

import numpy as np
import pandas as pd

from app.forecasting.frequency import irregular_intervals_pct


@dataclass
class DataValidationResult:
    """Outcome of pre-flight validation."""
    blocking_error: Optional[str] = None
    warnings: List[str] = field(default_factory=list)
    suggested_alternative_methods: List[str] = field(default_factory=list)


def _min_data_for_method(method: str, seasonal_period: int) -> int:
    """Return the minimum observation count required by a method.

    Rules match the old R app:
      - ARIMA non-seasonal: 10
      - ARIMA seasonal: 2*s + 5
      - ETS non-seasonal: 10
      - ETS seasonal: 2*freq + 5
      - Prophet: 15 (always; Prophet handles seasonal internally)
    """
    method = method.lower()
    if method == "prophet":
        return 15
    # ARIMA and ETS: seasonal if seasonal_period > 1
    if seasonal_period > 1:
        return 2 * seasonal_period + 5
    return 10


def _suggest_alternative_methods(n_obs: int, seasonal_period: int) -> List[str]:
    """Suggest methods that would work on the given data size."""
    suggestions: List[str] = []
    if n_obs >= 15:
        suggestions.append("Prophet")
    if n_obs >= 10:
        suggestions.append("ETS (non-seasonal)")
        suggestions.append("ARIMA (non-seasonal)")
    if seasonal_period > 1 and n_obs >= 2 * seasonal_period + 5:
        suggestions.append(f"ETS/ARIMA seasonal (s={seasonal_period})")
    return suggestions


def validate_for_method(
    series: pd.Series,
    method: str,
    seasonal_period: int = 1,
    *,
    prophet_yearly: bool = False,
    prophet_weekly: bool = False,
    prophet_daily: bool = False,
    dates: Optional[pd.DatetimeIndex] = None,
) -> DataValidationResult:
    """Run all pre-flight checks for a forecast request.

    Args:
        series: The time series values to forecast.
        method: "arima" | "ets" | "prophet"
        seasonal_period: Seasonal period length (1 = non-seasonal).
        prophet_yearly/weekly/daily: Prophet seasonality toggles for misconfiguration warnings.
        dates: Datetime index for irregular-intervals check. Optional.

    Returns:
        DataValidationResult with either a blocking_error or a populated warnings list.
    """
    result = DataValidationResult()

    if series is None or len(series) == 0:
        result.blocking_error = "Dataset is empty."
        return result

    n_obs = int(series.notna().sum())

    # Zero-variance check (blocking)
    values = series.dropna().to_numpy(dtype=float, copy=False)
    if len(values) > 0 and np.nanstd(values) == 0:
        result.blocking_error = "All values are identical; forecasting requires variation."
        return result

    # Minimum data check (blocking)
    required = _min_data_for_method(method, seasonal_period)
    if n_obs < required:
        alternatives = _suggest_alternative_methods(n_obs, seasonal_period)
        result.suggested_alternative_methods = alternatives
        method_label = method.upper() if method.lower() == "ets" else method.capitalize()
        alt_text = ", ".join(alternatives) if alternatives else "none available for this dataset size"
        seasonal_suffix = f" (seasonal, s={seasonal_period})" if seasonal_period > 1 and method.lower() != "prophet" else ""
        result.blocking_error = (
            f"{method_label}{seasonal_suffix} requires >= {required} observations; "
            f"dataset has {n_obs}. Try: {alt_text}."
        )
        return result

    # --- Warnings (non-blocking) ---

    # Prophet seasonality misconfigurations (US7)
    if method.lower() == "prophet":
        if prophet_yearly and n_obs < 730:
            result.warnings.append(
                f"Yearly seasonality enabled on only {n_obs} observations "
                f"(recommended >= 730). Consider disabling to avoid inventing yearly cycles."
            )
        if prophet_weekly and n_obs < 14:
            result.warnings.append(
                f"Weekly seasonality enabled on only {n_obs} observations "
                f"(recommended >= 14)."
            )
        if prophet_daily and n_obs < 30:
            result.warnings.append(
                f"Daily seasonality enabled on only {n_obs} observations "
                f"(recommended >= 30). Daily seasonality is typically for sub-daily data."
            )

    # Irregular-intervals warning
    if dates is not None and len(dates) >= 3:
        pct = irregular_intervals_pct(dates, tolerance=0.5)
        if pct > 10.0:
            result.warnings.append(
                f"Dataset has irregular intervals: {pct:.1f}% of gaps deviate >50% "
                f"from the median. Consider resampling to a regular grid."
            )

    return result
