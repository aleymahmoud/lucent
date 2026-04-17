"""
Statistical tests for forecast residuals.

Provides three tests that run on the actual model.resid array:
  - Ljung-Box       autocorrelation
  - Breusch-Pagan   heteroscedasticity
  - Shapiro-Wilk    normality

All three return a ResidualTestResult with a plain-English interpretation.
"""
from __future__ import annotations

import logging
from typing import Optional

import numpy as np
import pandas as pd

from app.schemas.diagnostics import ResidualTestResult


logger = logging.getLogger(__name__)


SIGNIFICANCE = 0.05


def ljung_box(residuals: np.ndarray, lags: Optional[int] = None) -> ResidualTestResult:
    """Ljung-Box test for autocorrelation at the first `lags` lags.

    H0: residuals are independently distributed (no autocorrelation).
    Reject (p < 0.05) => autocorrelation present => model is missing structure.
    """
    from statsmodels.stats.diagnostic import acorr_ljungbox

    residuals = np.asarray(residuals, dtype=float)
    residuals = residuals[np.isfinite(residuals)]
    n = len(residuals)
    if n < 8:
        return ResidualTestResult(
            test_name="Ljung-Box",
            statistic=float("nan"),
            p_value=float("nan"),
            interpretation=f"Skipped — only {n} residuals, need at least 8.",
            passes=False,
        )

    # Rule-of-thumb lag: min(10, n/5)
    auto_lags = max(1, min(10, n // 5))
    lag = lags or auto_lags

    try:
        result_df = acorr_ljungbox(residuals, lags=[lag], return_df=True)
        stat = float(result_df["lb_stat"].iloc[0])
        p = float(result_df["lb_pvalue"].iloc[0])
    except Exception as exc:
        logger.warning(f"Ljung-Box failed: {exc}")
        return ResidualTestResult(
            test_name="Ljung-Box",
            statistic=float("nan"),
            p_value=float("nan"),
            interpretation=f"Test failed: {exc}",
            passes=False,
        )

    passes = p > SIGNIFICANCE
    interpretation = (
        f"No significant autocorrelation detected at lag {lag} (p = {p:.3f})."
        if passes
        else f"Significant autocorrelation detected at lag {lag} (p = {p:.3f}); model may be missing structure."
    )
    return ResidualTestResult(
        test_name="Ljung-Box",
        statistic=round(stat, 4),
        p_value=round(p, 6),
        interpretation=interpretation,
        passes=passes,
    )


def breusch_pagan(
    residuals: np.ndarray, fitted: Optional[np.ndarray] = None
) -> ResidualTestResult:
    """Breusch-Pagan test for heteroscedasticity.

    H0: residual variance is constant (homoscedastic).
    Reject (p < 0.05) => variance changes with the fitted value => non-constant variance.
    """
    from statsmodels.stats.diagnostic import het_breuschpagan

    residuals = np.asarray(residuals, dtype=float)

    if fitted is None:
        # Without fitted values, regress against a linear time index as a proxy.
        fitted = np.arange(len(residuals), dtype=float)
    else:
        fitted = np.asarray(fitted, dtype=float)

    # Align and drop NaNs
    mask = np.isfinite(residuals) & np.isfinite(fitted)
    residuals = residuals[mask]
    fitted = fitted[mask]
    n = len(residuals)
    if n < 10:
        return ResidualTestResult(
            test_name="Breusch-Pagan",
            statistic=float("nan"),
            p_value=float("nan"),
            interpretation=f"Skipped — only {n} residuals, need at least 10.",
            passes=False,
        )

    # Design matrix: intercept + fitted value as the single exog.
    exog = np.column_stack([np.ones(n), fitted])

    try:
        lm, lm_p, _, _ = het_breuschpagan(residuals, exog)
    except Exception as exc:
        logger.warning(f"Breusch-Pagan failed: {exc}")
        return ResidualTestResult(
            test_name="Breusch-Pagan",
            statistic=float("nan"),
            p_value=float("nan"),
            interpretation=f"Test failed: {exc}",
            passes=False,
        )

    p = float(lm_p)
    stat = float(lm)
    passes = p > SIGNIFICANCE
    interpretation = (
        f"Residual variance appears constant (homoscedastic, p = {p:.3f})."
        if passes
        else f"Residual variance changes over time (heteroscedastic, p = {p:.3f}); forecast intervals may be unreliable."
    )
    return ResidualTestResult(
        test_name="Breusch-Pagan",
        statistic=round(stat, 4),
        p_value=round(p, 6),
        interpretation=interpretation,
        passes=passes,
    )


def shapiro_wilk(residuals: np.ndarray) -> ResidualTestResult:
    """Shapiro-Wilk test for normality.

    H0: residuals are drawn from a normal distribution.
    Reject (p < 0.05) => non-normal => prediction intervals may be miscalibrated.
    scipy.stats.shapiro rejects n > 5000; we skip in that case.
    """
    from scipy.stats import shapiro

    residuals = np.asarray(residuals, dtype=float)
    residuals = residuals[np.isfinite(residuals)]
    n = len(residuals)
    if n < 3:
        return ResidualTestResult(
            test_name="Shapiro-Wilk",
            statistic=float("nan"),
            p_value=float("nan"),
            interpretation=f"Skipped — only {n} residuals, need at least 3.",
            passes=False,
        )
    if n > 5000:
        return ResidualTestResult(
            test_name="Shapiro-Wilk",
            statistic=float("nan"),
            p_value=float("nan"),
            interpretation=f"Skipped — {n} residuals exceeds Shapiro-Wilk's 5000-observation limit.",
            passes=False,
        )

    try:
        stat, p = shapiro(residuals)
    except Exception as exc:
        logger.warning(f"Shapiro-Wilk failed: {exc}")
        return ResidualTestResult(
            test_name="Shapiro-Wilk",
            statistic=float("nan"),
            p_value=float("nan"),
            interpretation=f"Test failed: {exc}",
            passes=False,
        )

    p = float(p)
    stat = float(stat)
    passes = p > SIGNIFICANCE
    interpretation = (
        f"Residuals are consistent with a normal distribution (p = {p:.3f})."
        if passes
        else f"Residuals deviate from normality (p = {p:.3f}); prediction intervals may be miscalibrated."
    )
    return ResidualTestResult(
        test_name="Shapiro-Wilk",
        statistic=round(stat, 4),
        p_value=round(p, 6),
        interpretation=interpretation,
        passes=passes,
    )


def run_all_tests(
    residuals: np.ndarray, fitted: Optional[np.ndarray] = None
) -> list[ResidualTestResult]:
    """Convenience: run all three tests, return as a list."""
    return [
        ljung_box(residuals),
        breusch_pagan(residuals, fitted),
        shapiro_wilk(residuals),
    ]
