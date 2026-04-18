"""Tests for HTML diagnostics report export."""
from __future__ import annotations

from datetime import datetime

from app.schemas.diagnostics import (
    DiagnosticsFullResponse,
    ModelParametersResponse,
    QualityIndicatorsResponse,
    ResidualAnalysisResponse,
    ResidualTestResult,
    SeasonalityAnalysisResponse,
)
from app.schemas.forecast import (
    ForecastMethod,
    ForecastResultResponse,
    ForecastStatus,
    MetricsResponse,
    ModelSummaryResponse,
    PredictionResponse,
)
from app.services.report_exporter import render_html


def _forecast() -> ForecastResultResponse:
    return ForecastResultResponse(
        id="f-1",
        dataset_id="d-1",
        entity_id="ENTITY_A",
        method=ForecastMethod.ARIMA,
        status=ForecastStatus.COMPLETED,
        progress=100,
        predictions=[
            PredictionResponse(
                date="2024-01-01", value=10.0, lower_bound=8.0, upper_bound=12.0
            )
        ],
        metrics=MetricsResponse(mae=1.2, rmse=1.5, mape=2.3),
        model_summary=ModelSummaryResponse(
            method="arima",
            parameters={"p": 1, "d": 1, "q": 1},
            residuals=[0.1, -0.2, 0.15, -0.05, 0.12],
        ),
        cv_results=None,
        created_at=datetime.utcnow(),
    )


def _diagnostics(is_synthetic: bool = False) -> DiagnosticsFullResponse:
    return DiagnosticsFullResponse(
        forecast_id="f-1",
        entity_id="ENTITY_A",
        method="arima",
        residual_analysis=ResidualAnalysisResponse(
            residuals=[0.1, -0.2, 0.15, -0.05, 0.12],
            residual_mean=0.0,
            residual_std=0.15,
            acf=[],
            pacf=[],
            acf_confidence=0.2,
            ljung_box={"statistic": 2.1, "p_value": 0.3},
            jarque_bera={"statistic": 0.4, "p_value": 0.8},
            is_white_noise=True,
            is_synthetic=is_synthetic,
            tests=[
                ResidualTestResult(
                    test_name="Ljung-Box",
                    statistic=2.1,
                    p_value=0.3,
                    interpretation="No autocorrelation detected",
                    passes=True,
                )
            ],
        ),
        model_parameters=ModelParametersResponse(
            method="arima",
            parameters={"p": 1, "d": 1, "q": 1},
            coefficients=[
                {"name": "ar.L1", "estimate": 0.45, "std_error": 0.08,
                 "z_stat": 5.6, "p_value": 0.001, "significant": True}
            ],
            aic=123.45,
            bic=130.0,
        ),
        seasonality=None,
        quality_indicators=QualityIndicatorsResponse(
            accuracy=85.0, stability=70.0, reliability=90.0, coverage=95.0,
        ),
    )


def test_render_html_contains_expected_sections():
    html = render_html(_forecast(), _diagnostics())
    assert "<html" in html.lower()
    assert "Forecast Diagnostics" in html
    assert "ENTITY_A" in html
    # Method surfaces somewhere (header + sections)
    assert "arima" in html.lower() or "ARIMA" in html
    # Statistical test row from residual_analysis.tests
    assert "Ljung-Box" in html
    assert "No autocorrelation detected" in html


def test_render_html_shows_banner_for_synthetic_residuals():
    html = render_html(_forecast(), _diagnostics(is_synthetic=True))
    assert "Residual detail is unavailable" in html or "historical record" in html.lower()


def test_render_html_quality_section_shows_four_scores():
    html = render_html(_forecast(), _diagnostics())
    for label in ("Accuracy", "Stability", "Reliability", "Coverage"):
        assert label in html


def test_render_html_includes_coefficient_row():
    html = render_html(_forecast(), _diagnostics())
    # ar.L1 should appear in the coefficients table
    assert "ar.L1" in html
