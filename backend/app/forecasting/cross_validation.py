"""
Cross-validation engine for time-series forecasting.

Supports rolling-window and expanding-window walk-forward CV.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass, field
from typing import Callable, List, Optional

import numpy as np
import pandas as pd

from app.forecasting.base import BaseForecaster


logger = logging.getLogger(__name__)


@dataclass
class CVFoldResult:
    fold_index: int
    train_size: int
    test_size: int
    mae: float
    rmse: float
    mape: float


@dataclass
class CVRunResult:
    folds: List[CVFoldResult] = field(default_factory=list)
    average_mae: float = 0.0
    average_rmse: float = 0.0
    average_mape: float = 0.0
    method: str = "rolling"
    reduced_folds: bool = False  # True if requested folds was reduced due to data size
    requested_folds: int = 0


def _metrics(y_true: np.ndarray, y_pred: np.ndarray) -> tuple[float, float, float]:
    """Compute MAE, RMSE, MAPE. Matches app.forecasting.metrics."""
    y_true = np.asarray(y_true, dtype=float)
    y_pred = np.asarray(y_pred, dtype=float)
    mask = np.isfinite(y_true) & np.isfinite(y_pred)
    y_true = y_true[mask]
    y_pred = y_pred[mask]
    if len(y_true) == 0:
        return float("nan"), float("nan"), float("nan")
    mae = float(np.mean(np.abs(y_true - y_pred)))
    rmse = float(np.sqrt(np.mean((y_true - y_pred) ** 2)))
    nonzero = y_true != 0
    if nonzero.any():
        mape = float(np.mean(np.abs((y_true[nonzero] - y_pred[nonzero]) / y_true[nonzero])) * 100.0)
    else:
        mape = float("nan")
    return mae, rmse, mape


def _plan_folds(
    n: int,
    folds: int,
    horizon: int,
    initial_train_ratio: float,
) -> tuple[int, int, int, bool]:
    """Determine initial_train size, step between folds, and adjusted fold count.

    Returns (initial_train, step, actual_folds, reduced)
    """
    # Follow old R rule for auto horizon: min(12, floor(n * 0.15))
    # But here we trust the caller-supplied `horizon`.
    initial_train = int(n * initial_train_ratio)
    if initial_train < 10:
        initial_train = max(10, int(n * 0.7))
    step = max(1, horizon // 2)

    # For rolling: we need at least `initial_train + (folds-1)*step + horizon` rows
    needed = initial_train + (folds - 1) * step + horizon
    reduced = False
    while folds > 1 and needed > n:
        folds -= 1
        needed = initial_train + (folds - 1) * step + horizon
        reduced = True

    if folds < 1:
        folds = 1
        reduced = True
    return initial_train, step, folds, reduced


def run_cv(
    series: pd.Series,
    forecaster_factory: Callable[[], BaseForecaster],
    folds: int,
    method: str,
    initial_train_size: float,
    horizon: int,
    exog: Optional[pd.DataFrame] = None,
) -> CVRunResult:
    """Run walk-forward cross-validation.

    Args:
        series: The full time series to validate against.
        forecaster_factory: Callable returning a fresh BaseForecaster instance per fold.
        folds: Requested number of folds (may be reduced if data is too short).
        method: "rolling" | "expanding"
        initial_train_size: Fraction of data for the first fold's training set (0.5-0.9).
        horizon: Forecast horizon (number of periods predicted per fold).
        exog: Optional exogenous variables aligned to `series`.

    Returns:
        CVRunResult with per-fold metrics and averages.
    """
    n = len(series)
    requested_folds = folds
    initial_train, step, folds, reduced = _plan_folds(n, folds, horizon, initial_train_size)

    result = CVRunResult(method=method, requested_folds=requested_folds, reduced_folds=reduced)

    for k in range(folds):
        if method == "expanding":
            train_start = 0
            train_end = initial_train + k * step
        else:  # rolling
            train_start = k * step
            train_end = train_start + initial_train

        test_start = train_end
        test_end = min(test_start + horizon, n)

        if test_end - test_start < 1 or train_end <= train_start:
            logger.debug(f"CV fold {k} skipped: insufficient remaining data")
            continue

        train = series.iloc[train_start:train_end]
        test = series.iloc[test_start:test_end]

        train_exog = exog.iloc[train_start:train_end] if exog is not None else None

        try:
            forecaster = forecaster_factory()
            forecaster.fit(train, exog=train_exog)
            output = forecaster.predict(len(test), exog=None)
            predictions = output.predictions["value"].to_numpy()
            mae, rmse, mape = _metrics(test.to_numpy(), predictions[: len(test)])
            result.folds.append(
                CVFoldResult(
                    fold_index=k,
                    train_size=int(train_end - train_start),
                    test_size=int(test_end - test_start),
                    mae=mae,
                    rmse=rmse,
                    mape=mape,
                )
            )
        except Exception as exc:
            logger.warning(f"CV fold {k} failed: {exc}")
            continue

    # Compute averages
    if result.folds:
        maes = [f.mae for f in result.folds if np.isfinite(f.mae)]
        rmses = [f.rmse for f in result.folds if np.isfinite(f.rmse)]
        mapes = [f.mape for f in result.folds if np.isfinite(f.mape)]
        result.average_mae = float(np.mean(maes)) if maes else float("nan")
        result.average_rmse = float(np.mean(rmses)) if rmses else float("nan")
        result.average_mape = float(np.mean(mapes)) if mapes else float("nan")

    return result
