"""
Diagnostics report export.

Generates a self-contained HTML report that can be printed to PDF from a browser.
"""
from __future__ import annotations

from datetime import datetime
from html import escape
from typing import Optional

from app.schemas.diagnostics import (
    DiagnosticsFullResponse,
    ResidualAnalysisResponse,
    ModelParametersResponse,
    QualityIndicatorsResponse,
)
from app.schemas.forecast import ForecastResultResponse


def _fmt(n, digits: int = 4) -> str:
    try:
        f = float(n)
        if not (f == f):  # NaN
            return "—"
        return f"{f:.{digits}f}"
    except (TypeError, ValueError):
        return "—"


def _fmt_pct(n) -> str:
    try:
        f = float(n)
        return f"{f:.2f}%"
    except (TypeError, ValueError):
        return "—"


def _render_residual_section(r: Optional[ResidualAnalysisResponse]) -> str:
    if r is None:
        return ""
    if r.is_synthetic:
        return """
        <section>
          <h2>Residual Analysis</h2>
          <p class="warn">
            Residual detail is unavailable for this historical record.
            Re-run the forecast to see complete residual analysis including
            ACF, Ljung-Box, Breusch-Pagan, and Shapiro-Wilk tests.
          </p>
        </section>
        """

    tests_html = ""
    if r.tests:
        tests_html = '<h3>Tests</h3><table class="tests"><thead><tr><th>Test</th><th>Statistic</th><th>p-value</th><th>Interpretation</th></tr></thead><tbody>'
        for t in r.tests:
            pass_class = "ok" if t.passes else "fail"
            tests_html += (
                f'<tr class="{pass_class}">'
                f'<td>{escape(t.test_name)}</td>'
                f'<td>{_fmt(t.statistic)}</td>'
                f'<td>{_fmt(t.p_value, 6)}</td>'
                f'<td>{escape(t.interpretation)}</td>'
                f'</tr>'
            )
        tests_html += "</tbody></table>"

    return f"""
    <section>
      <h2>Residual Analysis</h2>
      <div class="grid">
        <div><strong>Observations:</strong> {len(r.residuals)}</div>
        <div><strong>Mean:</strong> {_fmt(r.residual_mean)}</div>
        <div><strong>Std Dev:</strong> {_fmt(r.residual_std)}</div>
        <div><strong>White noise:</strong> {'Yes' if r.is_white_noise else 'No'}</div>
      </div>
      {tests_html}
    </section>
    """


def _render_parameters_section(p: Optional[ModelParametersResponse]) -> str:
    if p is None:
        return ""

    params_rows = "".join(
        f'<tr><td>{escape(str(k))}</td><td>{escape(str(v))}</td></tr>'
        for k, v in (p.parameters or {}).items()
    )

    coeff_html = ""
    coeffs = p.coefficients
    if coeffs and isinstance(coeffs, list):
        coeff_html = (
            '<h3>Coefficients</h3><table class="coeffs"><thead><tr>'
            '<th>Name</th><th>Estimate</th><th>Std. Err.</th><th>z-stat</th><th>p-value</th>'
            '</tr></thead><tbody>'
        )
        for c in coeffs:
            if not isinstance(c, dict):
                c = c.model_dump() if hasattr(c, "model_dump") else {}
            coeff_html += (
                f'<tr>'
                f'<td>{escape(str(c.get("name", "")))}</td>'
                f'<td>{_fmt(c.get("estimate"))}</td>'
                f'<td>{_fmt(c.get("std_error"))}</td>'
                f'<td>{_fmt(c.get("z_stat"), 3)}</td>'
                f'<td>{_fmt(c.get("p_value"), 6)}</td>'
                f'</tr>'
            )
        coeff_html += "</tbody></table>"

    return f"""
    <section>
      <h2>Model Parameters — {escape((p.method or '').upper())}</h2>
      <div class="grid">
        {'<div><strong>AIC:</strong> ' + _fmt(p.aic, 2) + '</div>' if p.aic is not None else ''}
        {'<div><strong>BIC:</strong> ' + _fmt(p.bic, 2) + '</div>' if p.bic is not None else ''}
      </div>
      {'<h3>Parameters</h3><table><tbody>' + params_rows + '</tbody></table>' if params_rows else ''}
      {coeff_html}
    </section>
    """


def _render_quality_section(q: Optional[QualityIndicatorsResponse]) -> str:
    if q is None:
        return ""
    return f"""
    <section>
      <h2>Quality Indicators</h2>
      <div class="grid">
        <div><strong>Accuracy:</strong> {_fmt(q.accuracy, 1)}</div>
        <div><strong>Stability:</strong> {_fmt(q.stability, 1)}</div>
        <div><strong>Reliability:</strong> {_fmt(q.reliability, 1)}</div>
        <div><strong>Coverage:</strong> {_fmt(q.coverage, 1)}</div>
      </div>
    </section>
    """


def _render_header(forecast: ForecastResultResponse, diagnostics: DiagnosticsFullResponse) -> str:
    return f"""
    <header>
      <h1>Forecast Diagnostics</h1>
      <div class="meta">
        <div><strong>Entity:</strong> {escape(diagnostics.entity_id or '—')}</div>
        <div><strong>Method:</strong> {escape((diagnostics.method or '').upper())}</div>
        <div><strong>Forecast ID:</strong> <code>{escape(diagnostics.forecast_id)}</code></div>
        <div><strong>Generated:</strong> {datetime.utcnow().isoformat(timespec='seconds')} UTC</div>
      </div>
    </header>
    """


def _render_metrics_section(forecast: ForecastResultResponse) -> str:
    m = forecast.metrics
    if m is None:
        return ""
    cv_html = ""
    if forecast.cv_results:
        cv = forecast.cv_results
        rows = "".join(
            f'<tr><td>Fold {i + 1}</td><td>{_fmt(f.mae)}</td><td>{_fmt(f.rmse)}</td><td>{_fmt_pct(f.mape)}</td></tr>'
            for i, f in enumerate(cv.metrics_per_fold)
        )
        avg = cv.average_metrics
        rows += f'<tr class="avg"><td>Average</td><td>{_fmt(avg.mae)}</td><td>{_fmt(avg.rmse)}</td><td>{_fmt_pct(avg.mape)}</td></tr>'
        cv_html = f"""
        <h3>Cross-Validation ({cv.method}, {cv.folds} folds)</h3>
        <table class="cv"><thead><tr><th>Fold</th><th>MAE</th><th>RMSE</th><th>MAPE</th></tr></thead>
          <tbody>{rows}</tbody>
        </table>
        """
    return f"""
    <section>
      <h2>In-Sample Metrics</h2>
      <div class="grid">
        <div><strong>MAE:</strong> {_fmt(m.mae)}</div>
        <div><strong>RMSE:</strong> {_fmt(m.rmse)}</div>
        <div><strong>MAPE:</strong> {_fmt_pct(m.mape)}</div>
        {'<div><strong>AIC:</strong> ' + _fmt(m.aic, 2) + '</div>' if m.aic is not None else ''}
        {'<div><strong>BIC:</strong> ' + _fmt(m.bic, 2) + '</div>' if m.bic is not None else ''}
      </div>
      {cv_html}
    </section>
    """


def render_html(forecast: ForecastResultResponse, diagnostics: DiagnosticsFullResponse) -> str:
    """Render a self-contained HTML diagnostics report."""
    style = """
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      max-width: 900px;
      margin: 2rem auto;
      padding: 0 1rem;
      color: #111;
      line-height: 1.4;
    }
    header { border-bottom: 2px solid #3b82f6; padding-bottom: 1rem; margin-bottom: 2rem; }
    h1 { margin: 0 0 0.5rem 0; color: #1e3a8a; }
    h2 { color: #1e3a8a; border-bottom: 1px solid #e5e7eb; padding-bottom: 0.3rem; margin-top: 2rem; }
    h3 { color: #333; margin-top: 1.5rem; }
    .meta { display: grid; grid-template-columns: repeat(2, 1fr); gap: 0.5rem 2rem; font-size: 0.9rem; }
    .grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 0.75rem; font-size: 0.9rem; }
    .grid > div { background: #f9fafb; padding: 0.5rem 0.75rem; border-radius: 4px; border: 1px solid #e5e7eb; }
    table { width: 100%; border-collapse: collapse; margin-top: 0.75rem; font-size: 0.9rem; }
    th, td { border: 1px solid #e5e7eb; padding: 0.4rem 0.6rem; text-align: left; }
    th { background: #f3f4f6; font-weight: 600; }
    table.tests tr.ok td { background: rgba(34, 197, 94, 0.08); }
    table.tests tr.fail td { background: rgba(239, 68, 68, 0.08); }
    table.cv tr.avg td { font-weight: 600; background: #eff6ff; }
    code { font-family: ui-monospace, "SF Mono", Menlo, Consolas, monospace; font-size: 0.85em; background: #f3f4f6; padding: 0 0.3em; border-radius: 3px; }
    .warn { background: #fef3c7; border: 1px solid #f59e0b; padding: 1rem; border-radius: 4px; color: #78350f; }
    @media print { body { margin: 0; max-width: none; } header { page-break-after: avoid; } section { page-break-inside: avoid; } }
    """

    body = "".join([
        _render_header(forecast, diagnostics),
        _render_metrics_section(forecast),
        _render_residual_section(diagnostics.residual_analysis),
        _render_parameters_section(diagnostics.model_parameters),
        _render_quality_section(diagnostics.quality_indicators),
    ])

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Diagnostics — {escape(diagnostics.entity_id or '')}</title>
  <style>{style}</style>
</head>
<body>{body}</body>
</html>"""
