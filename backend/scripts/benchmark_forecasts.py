"""
Forecast accuracy benchmark — spec 004 US6.

Runs each forecast method on the 20 synthetic datasets from
`tests/data/synthetic.py::make_benchmark_suite`, computes CV MAPE/MAE/RMSE,
and writes a deterministic baseline.json.

Usage:
    cd backend && PYTHONPATH=. python scripts/benchmark_forecasts.py [--out PATH]

The output is designed to be version-controlled so future runs can
regress against it.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
import warnings
from pathlib import Path
from typing import Any, Dict, List

# Ensure the project root is on sys.path when run directly
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import numpy as np
import pandas as pd

# Silence statsmodels / pandas chatter during long benchmarks
warnings.filterwarnings("ignore")

from app.forecasting.arima import ARIMAForecaster
from app.forecasting.cross_validation import run_cv as run_cv_engine
from app.forecasting.ets import ETSForecaster
from tests.data.synthetic import make_benchmark_suite


DEFAULT_OUT = Path(__file__).resolve().parent.parent.parent / "specs" / "004-test-coverage-backfill" / "baseline.json"
CV_FOLDS = 3
CV_METHOD = "rolling"
CV_INITIAL = 0.7
CV_HORIZON = 7


def _prophet_available() -> bool:
    try:
        import cmdstanpy
        cmdstanpy.cmdstan_path()
        return True
    except Exception:
        return False


def _build_forecaster(method: str, frequency: str = "D"):
    if method == "arima":
        return ARIMAForecaster(frequency=frequency, auto=True)
    if method == "ets":
        return ETSForecaster(frequency=frequency, auto=True)
    if method == "prophet":
        from app.forecasting.prophet_forecaster import ProphetForecaster
        return ProphetForecaster(
            frequency=frequency,
            yearly_seasonality=False,
            weekly_seasonality=True,
            daily_seasonality=False,
        )
    raise ValueError(f"Unknown method: {method}")


def _infer_frequency(series: pd.Series) -> str:
    """Infer a pandas frequency label for the synthetic series.

    Falls back to median-interval estimation when pandas refuses to infer
    (e.g. fewer than 3 timestamps).
    """
    try:
        freq = pd.infer_freq(series.index)
    except Exception:
        freq = None
    if freq is None:
        # Median-delta fallback
        if len(series.index) >= 2:
            diffs = series.index.to_series().diff().dropna()
            if len(diffs):
                median_days = diffs.median().total_seconds() / 86400
                if median_days >= 28:
                    return "M"
                if median_days >= 6.5:
                    return "W"
        return "D"
    if freq.startswith("M"):
        return "M"
    if freq.startswith("W"):
        return "W"
    return "D"


def _benchmark_one(
    name: str, series: pd.Series, method: str
) -> Dict[str, Any]:
    """Run one (dataset, method) combo; return a flat record."""
    record: Dict[str, Any] = {
        "dataset": name,
        "method": method,
        "n": int(len(series)),
        "status": "pending",
    }

    # Cap horizon for very short series
    horizon = min(CV_HORIZON, max(2, len(series) // 5))
    freq = _infer_frequency(series)

    def factory():
        return _build_forecaster(method, frequency=freq)

    t0 = time.time()
    try:
        result = run_cv_engine(
            series=series,
            forecaster_factory=factory,
            folds=CV_FOLDS,
            method=CV_METHOD,
            initial_train_size=CV_INITIAL,
            horizon=horizon,
        )
    except Exception as exc:
        record["status"] = "failed"
        record["error"] = str(exc)[:200]
        record["elapsed_sec"] = round(time.time() - t0, 2)
        return record

    record["status"] = "ok" if result.folds else "no-folds"
    record["folds"] = len(result.folds)
    record["avg_mae"] = round(result.average_mae, 4) if np.isfinite(result.average_mae) else None
    record["avg_rmse"] = round(result.average_rmse, 4) if np.isfinite(result.average_rmse) else None
    record["avg_mape"] = round(result.average_mape, 4) if np.isfinite(result.average_mape) else None
    record["reduced_folds"] = bool(result.reduced_folds)
    record["elapsed_sec"] = round(time.time() - t0, 2)
    return record


def _summary(records: List[Dict[str, Any]]) -> Dict[str, Any]:
    by_method: Dict[str, List[Dict[str, Any]]] = {}
    for r in records:
        by_method.setdefault(r["method"], []).append(r)

    summary: Dict[str, Any] = {}
    for method, rows in by_method.items():
        ok_rows = [r for r in rows if r["status"] == "ok" and r.get("avg_mape") is not None]
        failed = sum(1 for r in rows if r["status"] == "failed")
        if ok_rows:
            summary[method] = {
                "n_datasets": len(rows),
                "success_rate": round(len(ok_rows) / len(rows) * 100.0, 1),
                "avg_mape": round(float(np.mean([r["avg_mape"] for r in ok_rows])), 3),
                "median_mape": round(float(np.median([r["avg_mape"] for r in ok_rows])), 3),
                "avg_mae": round(float(np.mean([r["avg_mae"] for r in ok_rows])), 3),
                "avg_rmse": round(float(np.mean([r["avg_rmse"] for r in ok_rows])), 3),
                "failed": failed,
            }
        else:
            summary[method] = {
                "n_datasets": len(rows),
                "success_rate": 0.0,
                "avg_mape": None,
                "failed": failed,
            }
    return summary


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--out", type=Path, default=DEFAULT_OUT,
        help=f"Output file (default: {DEFAULT_OUT})",
    )
    parser.add_argument(
        "--methods", nargs="+", default=None,
        help="Subset of methods to run (arima ets prophet)",
    )
    args = parser.parse_args()

    datasets = make_benchmark_suite()
    print(f"Benchmarking {len(datasets)} synthetic datasets")

    methods: List[str] = args.methods or ["arima", "ets"]
    if "prophet" in (args.methods or []):
        if not _prophet_available():
            print("Prophet requested but CmdStan not available — skipping")
            methods = [m for m in methods if m != "prophet"]
        else:
            methods.append("prophet") if "prophet" not in methods else None
    elif args.methods is None and _prophet_available():
        methods.append("prophet")

    print(f"Methods: {methods}")
    records: List[Dict[str, Any]] = []
    total_t0 = time.time()
    for i, (name, series) in enumerate(datasets.items(), 1):
        for method in methods:
            print(f"  [{i:2d}/{len(datasets)}] {name:30s} × {method:8s} ... ", end="", flush=True)
            rec = _benchmark_one(name, series, method)
            records.append(rec)
            status = rec["status"]
            if status == "ok":
                print(f"MAPE={rec['avg_mape']}  ({rec['elapsed_sec']}s)")
            else:
                print(f"{status}  ({rec['elapsed_sec']}s)")

    total_elapsed = round(time.time() - total_t0, 1)
    summary = _summary(records)
    out = {
        "generated_at": pd.Timestamp.utcnow().isoformat(),
        "total_elapsed_sec": total_elapsed,
        "cv": {"folds": CV_FOLDS, "method": CV_METHOD, "initial_train_size": CV_INITIAL, "horizon": CV_HORIZON},
        "methods": methods,
        "summary": summary,
        "records": records,
    }

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(out, indent=2))
    print(f"\nWrote {args.out}")
    print(f"Total: {total_elapsed}s")
    for m, s in summary.items():
        print(f"  {m}: avg_mape={s.get('avg_mape')}, success={s.get('success_rate')}%, failed={s.get('failed')}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
