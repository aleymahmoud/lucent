"""
Excel export for forecast results.

Generates multi-sheet .xlsx files using openpyxl via pandas.ExcelWriter.
"""
from __future__ import annotations

from io import BytesIO
from typing import List, Optional

import pandas as pd

from app.schemas.forecast import ForecastResultResponse, BatchForecastStatusResponse


def _sanitize_sheet_name(name: str, used: set) -> str:
    """Return a sheet name <= 31 chars, unique within `used`."""
    base = (name or "Sheet").strip()[:28] or "Sheet"
    candidate = base[:31]
    i = 2
    while candidate in used:
        suffix = f"_{i}"
        candidate = f"{base[:31 - len(suffix)]}{suffix}"
        i += 1
    used.add(candidate)
    return candidate


def export_single(result: ForecastResultResponse) -> BytesIO:
    """Export a single forecast result as multi-sheet .xlsx.

    Sheets:
      - Forecast    -> date / value / lower / upper
      - Metrics     -> metric -> value
      - Model       -> parameter -> value + coefficient table (if any)
      - CV          -> per-fold + averages (only if cv_results present)
    """
    buf = BytesIO()
    with pd.ExcelWriter(buf, engine="openpyxl") as writer:
        # Forecast sheet
        forecast_df = pd.DataFrame([
            {
                "Date": p.date,
                "Value": p.value,
                "Lower": p.lower_bound,
                "Upper": p.upper_bound,
            }
            for p in (result.predictions or [])
        ])
        forecast_df.to_excel(writer, sheet_name="Forecast", index=False)

        # Metrics sheet
        metrics_rows = []
        if result.metrics:
            for field in ("mae", "rmse", "mape", "mse", "r2", "aic", "bic"):
                val = getattr(result.metrics, field, None)
                metrics_rows.append({"Metric": field.upper(), "Value": val})
        pd.DataFrame(metrics_rows).to_excel(writer, sheet_name="Metrics", index=False)

        # Model summary sheet
        if result.model_summary:
            param_rows = [
                {"Parameter": k, "Value": v}
                for k, v in (result.model_summary.parameters or {}).items()
            ]
            pd.DataFrame(param_rows).to_excel(writer, sheet_name="Model", index=False)

            # Coefficients (if available) on the same sheet, below a gap
            if result.model_summary.coefficients:
                coeffs = result.model_summary.coefficients
                coef_rows = [
                    c.model_dump() if hasattr(c, "model_dump") else c
                    for c in coeffs
                ]
                df_coef = pd.DataFrame(coef_rows)
                start_row = len(param_rows) + 3
                df_coef.to_excel(
                    writer, sheet_name="Model", index=False, startrow=start_row
                )

        # CV sheet
        if result.cv_results:
            cv = result.cv_results
            fold_rows = [
                {
                    "Fold": i + 1,
                    "MAE": m.mae,
                    "RMSE": m.rmse,
                    "MAPE": m.mape,
                }
                for i, m in enumerate(cv.metrics_per_fold)
            ]
            avg = {
                "Fold": "Average",
                "MAE": cv.average_metrics.mae,
                "RMSE": cv.average_metrics.rmse,
                "MAPE": cv.average_metrics.mape,
            }
            pd.DataFrame(fold_rows + [avg]).to_excel(
                writer, sheet_name="Cross-Validation", index=False
            )

    buf.seek(0)
    return buf


def export_batch(batch: BatchForecastStatusResponse) -> BytesIO:
    """Export a batch of forecasts to a multi-sheet .xlsx.

    Sheets:
      - Summary      -> one row per entity: status + metrics
      - All_Data     -> combined forecast rows for every entity
      - {Entity}     -> one sheet per entity (truncated / deduplicated names)
    """
    buf = BytesIO()
    with pd.ExcelWriter(buf, engine="openpyxl") as writer:
        used: set = set()

        # Summary sheet
        summary_rows = []
        for r in batch.results or []:
            row = {
                "Entity": r.entity_id,
                "Status": r.status.value if hasattr(r.status, "value") else r.status,
                "Method": r.method.value if hasattr(r.method, "value") else r.method,
            }
            if r.metrics:
                row.update({
                    "MAE": r.metrics.mae,
                    "RMSE": r.metrics.rmse,
                    "MAPE": r.metrics.mape,
                })
            summary_rows.append(row)
        pd.DataFrame(summary_rows).to_excel(
            writer, sheet_name=_sanitize_sheet_name("Summary", used), index=False
        )

        # Combined All_Data sheet
        all_rows = []
        for r in batch.results or []:
            for p in r.predictions or []:
                all_rows.append({
                    "Entity": r.entity_id,
                    "Date": p.date,
                    "Type": "Forecast",
                    "Value": p.value,
                    "Lower": p.lower_bound,
                    "Upper": p.upper_bound,
                })
        pd.DataFrame(all_rows).to_excel(
            writer, sheet_name=_sanitize_sheet_name("All_Data", used), index=False
        )

        # Per-entity sheets
        for r in batch.results or []:
            if not r.predictions:
                continue
            df = pd.DataFrame([
                {
                    "Date": p.date,
                    "Value": p.value,
                    "Lower": p.lower_bound,
                    "Upper": p.upper_bound,
                }
                for p in r.predictions
            ])
            sheet_name = _sanitize_sheet_name(r.entity_id or "Entity", used)
            df.to_excel(writer, sheet_name=sheet_name, index=False)

    buf.seek(0)
    return buf
