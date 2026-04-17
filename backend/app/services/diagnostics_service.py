"""
Diagnostics Service - Forecast diagnostic analysis
Computes residual analysis, model parameters, seasonality decomposition, and quality indicators.
"""
import json
import logging
import math
from typing import Optional, List, Dict, Any

import numpy as np

from app.db.redis_client import get_redis
from app.schemas.forecast import ForecastResultResponse, ForecastStatus
from app.schemas.diagnostics import (
    ResidualAnalysisResponse,
    ModelParametersResponse,
    SeasonalityAnalysisResponse,
    QualityIndicatorsResponse,
    ModelComparisonResponse,
    DiagnosticsFullResponse,
)

logger = logging.getLogger(__name__)

REDIS_FORECAST_PREFIX = "forecast:"
_LAGS = 20          # ACF/PACF lags


class DiagnosticsService:
    """Service for computing diagnostics on completed forecast results"""

    def __init__(self, tenant_id: str, user_id: Optional[str] = None):
        self.tenant_id = tenant_id
        self.user_id = user_id

    # ============================================
    # Redis Fetch
    # ============================================

    async def _fetch_result(self, forecast_id: str) -> Optional[ForecastResultResponse]:
        """Fetch a ForecastResultResponse from Redis. Returns None when missing."""
        try:
            redis = await get_redis()
            if redis is None:
                logger.warning("Redis unavailable — cannot retrieve forecast result")
                return None

            key = f"{REDIS_FORECAST_PREFIX}{forecast_id}"
            raw = await redis.get(key)
            if raw is None:
                return None

            if isinstance(raw, bytes):
                raw = raw.decode("utf-8")

            data = json.loads(raw)
            return ForecastResultResponse(**data)

        except Exception as e:
            logger.error(f"Error fetching forecast result {forecast_id}: {e}")
            return None

    # ============================================
    # Residual Array Reconstruction
    # ============================================

    def _extract_residuals(self, result: ForecastResultResponse) -> Optional[List[float]]:
        """
        Retrieve the real residuals array persisted by the ForecastService.

        Returns None when the record predates residual persistence (legacy record);
        callers are expected to set `is_synthetic=True` and surface a banner to the
        user rather than fabricate data.
        """
        if result.model_summary is None:
            return None

        # New canonical location: model_summary.residuals (Pydantic field).
        if result.model_summary.residuals:
            arr = [float(v) for v in result.model_summary.residuals if v is not None]
            return arr if len(arr) >= 4 else None

        # Legacy location fallback: model_summary.diagnostics["residuals"].
        diag = result.model_summary.diagnostics or {}
        if isinstance(diag.get("residuals"), list):
            arr = [float(v) for v in diag["residuals"] if v is not None]
            return arr if len(arr) >= 4 else None

        # No real residuals available — do NOT synthesise.
        return None

    # ============================================
    # Residual Analysis
    # ============================================

    async def get_residual_analysis(
        self, forecast_id: str
    ) -> Optional[ResidualAnalysisResponse]:
        """Compute ACF/PACF and full test battery on the real residual array.

        Returns a response with `is_synthetic=True` when the forecast was saved
        before residual persistence shipped — the frontend shows a banner
        instructing the user to re-run the forecast.
        """
        result = await self._fetch_result(forecast_id)
        if result is None:
            return None

        residuals = self._extract_residuals(result)

        # Legacy record — no real residuals available
        if residuals is None:
            empty = [0.0]
            return ResidualAnalysisResponse(
                residuals=[],
                residual_mean=0.0,
                residual_std=0.0,
                acf=[],
                pacf=[],
                acf_confidence=0.0,
                ljung_box={"statistic": 0.0, "p_value": 1.0},
                jarque_bera={"statistic": 0.0, "p_value": 1.0},
                is_white_noise=False,
                is_synthetic=True,
                tests=[],
            )

        try:
            from statsmodels.tsa.stattools import acf as sm_acf, pacf as sm_pacf
            from statsmodels.stats.diagnostic import acorr_ljungbox
            from scipy.stats import jarque_bera as sp_jb
            from app.forecasting.residual_tests import run_all_tests

            arr = np.array(residuals, dtype=float)
            n = len(arr)
            lags = min(_LAGS, n // 2 - 1)
            lags = max(lags, 1)

            acf_vals = sm_acf(arr, nlags=lags, fft=True).tolist()
            pacf_vals = sm_pacf(arr, nlags=lags, method="ywm").tolist()
            conf = 1.96 / math.sqrt(n)

            lb_result = acorr_ljungbox(arr, lags=[lags], return_df=True)
            lb_stat = float(lb_result["lb_stat"].iloc[-1])
            lb_pvalue = float(lb_result["lb_pvalue"].iloc[-1])

            jb_stat, jb_pvalue = sp_jb(arr)

            # Full battery: Ljung-Box + Breusch-Pagan + Shapiro-Wilk
            tests = run_all_tests(arr, fitted=None)

            return ResidualAnalysisResponse(
                residuals=arr.tolist(),
                residual_mean=round(float(np.mean(arr)), 6),
                residual_std=round(float(np.std(arr)), 6),
                acf=[round(v, 6) for v in acf_vals],
                pacf=[round(v, 6) for v in pacf_vals],
                acf_confidence=round(conf, 6),
                ljung_box={
                    "statistic": round(lb_stat, 6),
                    "p_value": round(lb_pvalue, 6),
                },
                jarque_bera={
                    "statistic": round(float(jb_stat), 6),
                    "p_value": round(float(jb_pvalue), 6),
                },
                is_white_noise=lb_pvalue > 0.05,
                is_synthetic=False,
                tests=tests,
            )

        except Exception as e:
            logger.error(f"Residual analysis failed for {forecast_id}: {e}")
            return None

    # ============================================
    # Model Parameters
    # ============================================

    async def get_model_parameters(
        self, forecast_id: str
    ) -> Optional[ModelParametersResponse]:
        """Extract model parameters and information criteria from model_summary."""
        result = await self._fetch_result(forecast_id)
        if result is None:
            return None

        if result.model_summary is None:
            return None

        summary = result.model_summary
        metrics = result.metrics

        # Pass coefficients through as-is — the list-of-ModelCoefficient shape
        # is serialised directly; legacy Dict shape is also acceptable to the
        # response schema (Dict[str, Any]).
        coefficients_out = None
        if summary.coefficients:
            coefficients_out = [
                c.model_dump() if hasattr(c, "model_dump") else c
                for c in summary.coefficients
            ]

        return ModelParametersResponse(
            method=summary.method,
            parameters=summary.parameters or {},
            coefficients=coefficients_out,
            standard_errors=None,  # Covered inside each coefficient now
            aic=metrics.aic if metrics else None,
            bic=metrics.bic if metrics else None,
        )

    # ============================================
    # Seasonality Analysis
    # ============================================

    async def get_seasonality_analysis(
        self, forecast_id: str
    ) -> Optional[SeasonalityAnalysisResponse]:
        """
        Estimate seasonal and trend strength from prediction values.

        Uses STL decomposition when enough observations are available (>= 2 full cycles),
        otherwise falls back to autocorrelation-based period detection.
        """
        result = await self._fetch_result(forecast_id)
        if result is None:
            return None

        if not result.predictions:
            return None

        values = [p.value for p in result.predictions]
        n = len(values)

        if n < 4:
            return SeasonalityAnalysisResponse()

        arr = np.array(values, dtype=float)

        # --- Candidate periods ---
        candidate_periods = [7, 12, 4, 52, 30]
        detected_period: Optional[int] = None

        for period in candidate_periods:
            if n >= 2 * period:
                try:
                    autocorr = float(np.corrcoef(arr[:-period], arr[period:])[0, 1])
                    if autocorr > 0.3:
                        detected_period = period
                        break
                except Exception:
                    continue

        # --- STL Decomposition (requires >= 2 full cycles) ---
        seasonal_component: Optional[List[float]] = None
        seasonal_strength: Optional[float] = None
        trend_strength: Optional[float] = None

        if detected_period and n >= 2 * detected_period:
            try:
                from statsmodels.tsa.seasonal import STL
                stl = STL(arr, period=detected_period, robust=True)
                res = stl.fit()

                seasonal_component = [round(v, 4) for v in res.seasonal.tolist()]

                # Strength metrics (variance-decomposition approach)
                resid = res.resid
                seasonal = res.seasonal
                trend = res.trend

                var_resid = float(np.var(resid))
                var_seasonal_resid = float(np.var(seasonal + resid))
                var_trend_resid = float(np.var(trend + resid))

                if var_seasonal_resid > 0:
                    seasonal_strength = round(
                        max(0.0, 1.0 - var_resid / var_seasonal_resid), 4
                    )
                if var_trend_resid > 0:
                    trend_strength = round(
                        max(0.0, 1.0 - var_resid / var_trend_resid), 4
                    )

            except Exception as e:
                logger.debug(f"STL decomposition failed for {forecast_id}: {e}")

        return SeasonalityAnalysisResponse(
            seasonal_strength=seasonal_strength,
            trend_strength=trend_strength,
            detected_period=detected_period,
            seasonal_component=seasonal_component,
        )

    # ============================================
    # Quality Indicators
    # ============================================

    async def get_quality_indicators(
        self, forecast_id: str
    ) -> Optional[QualityIndicatorsResponse]:
        """
        Compute four 0-100 quality scores:
        - accuracy   : based on MAPE (MAPE < 10 => 100)
        - stability  : inverse coefficient of variation of residuals
        - reliability: based on Ljung-Box p-value
        - coverage   : fraction of predictions whose interval contains the predicted value
                       (used as a proxy when actual observations are unavailable)
        """
        result = await self._fetch_result(forecast_id)
        if result is None:
            return None

        metrics = result.metrics

        # --- Accuracy ---
        if metrics and metrics.mape is not None:
            mape = float(metrics.mape)
            accuracy = round(max(0.0, 100.0 - mape * 10.0), 2)
        else:
            accuracy = 50.0  # neutral when MAPE unavailable

        # --- Stability ---
        residuals = self._extract_residuals(result)
        if residuals and len(residuals) >= 4:
            arr = np.array(residuals, dtype=float)
            mean_abs = float(np.mean(np.abs(arr)))
            std_res = float(np.std(arr))
            if mean_abs > 1e-9:
                cv = std_res / (mean_abs + 1e-9)
                # cv = 0 => perfect stability (100), cv >= 2 => 0
                stability = round(max(0.0, 100.0 * (1.0 - min(cv / 2.0, 1.0))), 2)
            else:
                stability = 100.0
        else:
            stability = 50.0  # neutral when residuals unavailable

        # --- Reliability (Ljung-Box) ---
        try:
            residual_analysis = await self.get_residual_analysis(forecast_id)
            if residual_analysis is not None:
                lb_p = residual_analysis.ljung_box["p_value"]
                if lb_p >= 0.05:
                    reliability = 100.0
                elif lb_p <= 0.01:
                    reliability = 0.0
                else:
                    # linear interpolation between 0.01 and 0.05
                    reliability = round(100.0 * (lb_p - 0.01) / (0.05 - 0.01), 2)
            else:
                reliability = 50.0
        except Exception:
            reliability = 50.0

        # --- Coverage ---
        # Proxy: fraction of prediction points where the interval width is
        # at least as large as twice the residual std (tight interval = lower coverage).
        coverage = 50.0
        if result.predictions:
            preds = result.predictions
            try:
                widths = [
                    abs(p.upper_bound - p.lower_bound) for p in preds
                ]
                if residuals and len(residuals) >= 4:
                    res_std = float(np.std(residuals))
                    # A good 95% interval should be ~4*std wide (±2*std)
                    expected_width = 4.0 * res_std
                    if expected_width > 0:
                        ratios = [min(w / expected_width, 1.0) for w in widths]
                        coverage = round(100.0 * float(np.mean(ratios)), 2)
                    else:
                        coverage = 100.0
            except Exception:
                coverage = 50.0

        return QualityIndicatorsResponse(
            accuracy=accuracy,
            stability=stability,
            reliability=reliability,
            coverage=coverage,
        )

    # ============================================
    # Model Comparison
    # ============================================

    async def compare_models(
        self, forecast_ids: List[str]
    ) -> ModelComparisonResponse:
        """
        Fetch multiple forecast results and rank them by a composite score.

        Composite score = 0.4*accuracy + 0.3*reliability + 0.2*stability + 0.1*coverage
        """
        models: List[Dict[str, Any]] = []

        for fid in forecast_ids:
            result = await self._fetch_result(fid)
            if result is None:
                continue

            quality = await self.get_quality_indicators(fid)

            entry: Dict[str, Any] = {
                "forecast_id": fid,
                "method": result.method.value if result.method else "unknown",
                "entity_id": result.entity_id,
                "metrics": result.metrics.model_dump() if result.metrics else {},
                "quality": quality.model_dump() if quality else {},
                "composite_score": 0.0,
            }

            if quality:
                composite = (
                    0.4 * quality.accuracy
                    + 0.3 * quality.reliability
                    + 0.2 * quality.stability
                    + 0.1 * quality.coverage
                )
                entry["composite_score"] = round(composite, 2)

            models.append(entry)

        if not models:
            # Return empty comparison rather than crashing
            return ModelComparisonResponse(models=[], best_model="")

        # Sort by composite_score descending
        models.sort(key=lambda m: m["composite_score"], reverse=True)
        best_model = models[0]["forecast_id"]

        return ModelComparisonResponse(models=models, best_model=best_model)

    # ============================================
    # Full Diagnostics Bundle
    # ============================================

    async def get_full_diagnostics(
        self, forecast_id: str
    ) -> Optional[DiagnosticsFullResponse]:
        """Assemble all sub-analyses into a single response."""
        result = await self._fetch_result(forecast_id)
        if result is None:
            return None

        # Run all sub-analyses in sequence (lightweight enough not to parallelise)
        residual_analysis = await self.get_residual_analysis(forecast_id)
        model_parameters = await self.get_model_parameters(forecast_id)
        seasonality = await self.get_seasonality_analysis(forecast_id)
        quality_indicators = await self.get_quality_indicators(forecast_id)

        return DiagnosticsFullResponse(
            forecast_id=forecast_id,
            entity_id=result.entity_id,
            method=result.method.value if result.method else "unknown",
            residual_analysis=residual_analysis,
            model_parameters=model_parameters,
            seasonality=seasonality,
            quality_indicators=quality_indicators,
        )
