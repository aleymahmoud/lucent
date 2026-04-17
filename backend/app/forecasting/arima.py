"""
ARIMA Forecaster - ARIMA/SARIMA implementation using statsmodels
"""
import warnings
from typing import Dict, Any, Optional, Tuple
import pandas as pd
import numpy as np
import logging

from statsmodels.tsa.arima.model import ARIMA
from statsmodels.tsa.statespace.sarimax import SARIMAX
from statsmodels.tsa.stattools import adfuller, acf, pacf

from .base import BaseForecaster, ForecastOutput

logger = logging.getLogger(__name__)

# Suppress statsmodels warnings
warnings.filterwarnings('ignore', category=UserWarning)
warnings.filterwarnings('ignore', category=FutureWarning)


class ARIMAForecaster(BaseForecaster):
    """ARIMA/SARIMA forecaster using statsmodels"""

    def __init__(
        self,
        frequency: str = "D",
        confidence_level: float = 0.95,
        order: Tuple[int, int, int] = (1, 1, 1),
        seasonal_order: Optional[Tuple[int, int, int, int]] = None,
        auto: bool = True
    ):
        """
        Initialize ARIMA forecaster.

        Args:
            frequency: Data frequency ('D', 'W', 'M')
            confidence_level: Confidence level for intervals
            order: (p, d, q) - AR order, differencing, MA order
            seasonal_order: (P, D, Q, s) - Seasonal parameters
            auto: Whether to auto-detect parameters
        """
        super().__init__(frequency, confidence_level)
        self.order = order
        self.seasonal_order = seasonal_order
        self.auto = auto

    def fit(self, y: pd.Series, exog: Optional[pd.DataFrame] = None) -> None:
        """Fit ARIMA model with cascading fallback on failure.

        Fallback levels:
            0 = primary attempt (full auto-ARIMA or user-supplied order)
            1 = simpler non-seasonal (max p=q=2, d=1, no seasonal)
            2 = ARIMA(1,1,1)
        """
        y = self._validate_data(y)
        self._training_data = y
        self.fallback_level = 0

        # Auto-detect parameters if enabled
        if self.auto:
            self.order, self.seasonal_order = self._auto_arima(y)
            logger.info(f"Auto-detected ARIMA order: {self.order}, seasonal: {self.seasonal_order}")

        # Attempt 1: primary
        if self._try_fit(y, self.order, self.seasonal_order):
            return

        # Attempt 2: simpler non-seasonal
        logger.info("ARIMA primary fit failed — retrying with simpler non-seasonal config")
        self.fallback_level = 1
        simpler_order, _ = self._simpler_auto_arima(y)
        if self._try_fit(y, simpler_order, None):
            self.order = simpler_order
            self.seasonal_order = None
            return

        # Attempt 3: ARIMA(1,1,1)
        logger.info("ARIMA simpler fit failed — falling back to ARIMA(1,1,1)")
        self.fallback_level = 2
        if self._try_fit(y, (1, 1, 1), None):
            self.order = (1, 1, 1)
            self.seasonal_order = None
            return

        # All attempts failed
        logger.error("ARIMA fallback chain exhausted")
        raise ValueError(
            "ARIMA could not fit this dataset. Try ETS or Prophet instead."
        )

    def _try_fit(
        self,
        y: pd.Series,
        order: Tuple[int, int, int],
        seasonal_order: Optional[Tuple[int, int, int, int]],
    ) -> bool:
        """Attempt to fit with the given order. Returns True on success."""
        try:
            with warnings.catch_warnings():
                warnings.simplefilter("ignore")
                if seasonal_order and seasonal_order[3] > 1:
                    self.model = SARIMAX(
                        y,
                        order=order,
                        seasonal_order=seasonal_order,
                        enforce_stationarity=False,
                        enforce_invertibility=False,
                    ).fit(disp=False)
                else:
                    self.model = ARIMA(y, order=order).fit()
            self.is_fitted = True
            logger.info(
                f"ARIMA fit OK (fallback_level={self.fallback_level}): "
                f"order={order}, seasonal_order={seasonal_order}, AIC={self.model.aic:.2f}"
            )
            return True
        except Exception as e:
            logger.warning(
                f"ARIMA fit failed at level {self.fallback_level} "
                f"(order={order}, seasonal={seasonal_order}): {e}"
            )
            return False

    def _simpler_auto_arima(self, y: pd.Series) -> Tuple[Tuple[int, int, int], None]:
        """Simpler grid search used by fallback level 1: max p=q=2, d=1, no seasonal."""
        best_aic = float('inf')
        best_order = (1, 1, 1)
        for p in range(3):
            for q in range(3):
                if p == 0 and q == 0:
                    continue
                try:
                    with warnings.catch_warnings():
                        warnings.simplefilter("ignore")
                        model = ARIMA(y, order=(p, 1, q)).fit()
                        if model.aic < best_aic:
                            best_aic = model.aic
                            best_order = (p, 1, q)
                except Exception:
                    continue
        return best_order, None

    def predict(self, horizon: int, exog: Optional[pd.DataFrame] = None) -> ForecastOutput:
        """Generate predictions"""
        if not self.is_fitted:
            raise ValueError("Model must be fitted before prediction")

        # Get predictions with confidence intervals
        forecast = self.model.get_forecast(steps=horizon)
        mean = forecast.predicted_mean
        conf_int = forecast.conf_int(alpha=1 - self.confidence_level)

        # Create future dates
        last_date = self._training_data.index[-1]
        future_dates = self._create_future_dates(last_date, horizon)

        # Build predictions DataFrame
        predictions = pd.DataFrame({
            'date': future_dates,
            'value': mean.values,
            'lower_bound': conf_int.iloc[:, 0].values,
            'upper_bound': conf_int.iloc[:, 1].values
        })

        # Calculate in-sample metrics
        fitted_values = self.model.fittedvalues
        residuals = self.model.resid

        # Align lengths for metric calculation
        min_len = min(len(self._training_data), len(fitted_values))
        y_true = self._training_data.values[-min_len:]
        y_pred = fitted_values.values[-min_len:]

        metrics = self._calculate_metrics(y_true, y_pred)

        # Add AIC/BIC to metrics
        metrics['aic'] = round(float(self.model.aic), 2)
        metrics['bic'] = round(float(self.model.bic), 2)

        # Build model summary
        model_summary = {
            'method': 'ARIMA',
            'order': list(self.order),
            'seasonal_order': list(self.seasonal_order) if self.seasonal_order else None,
            'aic': self.model.aic,
            'bic': self.model.bic,
            'fallback_level': getattr(self, 'fallback_level', 0),
            'parameters': {
                'p': self.order[0],
                'd': self.order[1],
                'q': self.order[2],
                'fallback_level': getattr(self, 'fallback_level', 0),
            }
        }

        # Build detailed coefficient list (estimate + SE + z-stat + p-value + significant)
        try:
            coefficients = []
            params = self.model.params
            try:
                bse = self.model.bse
            except Exception:
                bse = None
            try:
                tvalues = self.model.tvalues
            except Exception:
                tvalues = None
            try:
                pvalues = self.model.pvalues
            except Exception:
                pvalues = None

            for name, est in params.items():
                coef = {
                    "name": str(name),
                    "estimate": round(float(est), 6),
                }
                try:
                    if bse is not None and name in bse.index:
                        coef["std_error"] = round(float(bse[name]), 6)
                except Exception:
                    pass
                try:
                    if tvalues is not None and name in tvalues.index:
                        coef["z_stat"] = round(float(tvalues[name]), 4)
                except Exception:
                    pass
                try:
                    if pvalues is not None and name in pvalues.index:
                        p = float(pvalues[name])
                        coef["p_value"] = round(p, 6)
                        coef["significant"] = bool(p < 0.05)
                except Exception:
                    pass
                coefficients.append(coef)
            model_summary['coefficients'] = coefficients
        except Exception as exc:
            logger.warning(f"Failed to extract detailed coefficients: {exc}")

        return ForecastOutput(
            predictions=predictions,
            metrics=metrics,
            model_summary=model_summary,
            residuals=residuals.values if residuals is not None else None
        )

    def get_params(self) -> Dict[str, Any]:
        """Return model parameters"""
        return {
            'order': self.order,
            'seasonal_order': self.seasonal_order,
            'auto': self.auto,
            'frequency': self.frequency,
            'confidence_level': self.confidence_level
        }

    @classmethod
    def auto_detect_params(cls, y: pd.Series, frequency: str = "D") -> Dict[str, Any]:
        """Auto-detect optimal ARIMA parameters"""
        forecaster = cls(frequency=frequency, auto=True)
        y = forecaster._validate_data(y)
        order, seasonal_order = forecaster._auto_arima(y)

        return {
            'order': order,
            'seasonal_order': seasonal_order,
            'stationarity': forecaster._check_stationarity(y),
            'recommended_d': forecaster._find_d(y)
        }

    def _auto_arima(self, y: pd.Series) -> Tuple[Tuple[int, int, int], Optional[Tuple[int, int, int, int]]]:
        """Auto ARIMA parameter selection with joint seasonal search.

        If a seasonal period is detected, jointly searches (p,d,q) x (P,D,Q)
        using AIC. Matches old R `auto.arima` bounds: max p=3, max q=3, max P=2, max Q=2.
        Falls back to non-seasonal grid search if no seasonality detected.
        """
        import time

        d = self._find_d(y)
        seasonal_period = self._detect_seasonal_period(y)

        start_time = time.time()
        time_budget = 30.0  # seconds, per Decision 2 in research.md

        if seasonal_period is None or len(y) < 2 * seasonal_period + 5:
            # Non-seasonal path
            return self._non_seasonal_search(y, d), None

        # Joint seasonal search
        best_aic = float('inf')
        best_order = (1, d, 1)
        best_seasonal = (0, 0, 0, seasonal_period)
        no_improve_count = 0

        # Non-seasonal range: p in 0..3, q in 0..3 = 16 combos
        # Seasonal range: P in 0..2, D in 0..1, Q in 0..2 = 18 combos
        # Total worst case: 288 fits
        for P in range(3):
            for D in range(2):
                for Q in range(3):
                    if time.time() - start_time > time_budget:
                        logger.info(
                            f"ARIMA auto timed out after {time_budget}s; using best-so-far: "
                            f"order={best_order}, seasonal={best_seasonal}"
                        )
                        return best_order, best_seasonal if best_aic < float('inf') else None

                    for p in range(4):
                        for q in range(4):
                            if p == 0 and q == 0 and P == 0 and Q == 0:
                                continue
                            try:
                                with warnings.catch_warnings():
                                    warnings.simplefilter("ignore")
                                    model = SARIMAX(
                                        y,
                                        order=(p, d, q),
                                        seasonal_order=(P, D, Q, seasonal_period),
                                        enforce_stationarity=False,
                                        enforce_invertibility=False,
                                    ).fit(disp=False, maxiter=50)
                                    if model.aic < best_aic:
                                        best_aic = model.aic
                                        best_order = (p, d, q)
                                        best_seasonal = (P, D, Q, seasonal_period)
                                        no_improve_count = 0
                                    else:
                                        no_improve_count += 1
                                # Early termination after 20 non-improving combos
                                if no_improve_count > 20:
                                    logger.info(
                                        f"ARIMA auto early-terminated: no AIC improvement for 20 combos. "
                                        f"Best: order={best_order}, seasonal={best_seasonal}"
                                    )
                                    return best_order, best_seasonal
                            except Exception:
                                continue

        if best_aic == float('inf'):
            return (1, d, 1), None
        return best_order, best_seasonal

    def _non_seasonal_search(self, y: pd.Series, d: int) -> Tuple[int, int, int]:
        """Non-seasonal (p, d, q) grid search."""
        best_aic = float('inf')
        best_order = (1, d, 1)
        for p in range(4):
            for q in range(4):
                if p == 0 and q == 0:
                    continue
                try:
                    with warnings.catch_warnings():
                        warnings.simplefilter("ignore")
                        model = ARIMA(y, order=(p, d, q)).fit()
                        if model.aic < best_aic:
                            best_aic = model.aic
                            best_order = (p, d, q)
                except Exception:
                    continue
        return best_order

    def _detect_seasonal_period(self, y: pd.Series) -> Optional[int]:
        """Detect the dominant seasonal period (if any) via ACF.

        Stricter than before: threshold 0.4 and period must repeat across at least 2 cycles.
        """
        n = len(y)
        seasonal_periods = {
            'D': [7, 30, 365],
            'W': [4, 52],
            'M': [12],
            'Q': [4],
            'Y': [],
        }
        periods_to_check = seasonal_periods.get(self.frequency, [])

        for period in periods_to_check:
            # Need at least 2 full cycles
            if n < 2 * period:
                continue
            try:
                acf_values = acf(y.dropna(), nlags=min(n - 1, 2 * period + 1), fft=True)
                # Stricter threshold; also confirm repetition at 2*period
                lag1 = abs(acf_values[period]) if len(acf_values) > period else 0
                lag2 = abs(acf_values[2 * period]) if len(acf_values) > 2 * period else 0
                if lag1 > 0.4 and lag2 > 0.25:
                    return period
            except Exception:
                continue
        return None

    def _find_d(self, y: pd.Series) -> int:
        """Find optimal differencing order using ADF test"""
        max_d = 2
        for d in range(max_d + 1):
            if d == 0:
                test_series = y
            else:
                test_series = y.diff(d).dropna()

            if len(test_series) < 10:
                return d

            try:
                result = adfuller(test_series, autolag='AIC')
                p_value = result[1]
                if p_value < 0.05:  # Stationary at 5% level
                    return d
            except Exception:
                continue

        return 1  # Default to d=1

    def _detect_seasonality(self, y: pd.Series) -> Optional[Tuple[int, int, int, int]]:
        """Deprecated — kept for backward compatibility.

        Prefer _detect_seasonal_period() + joint search in _auto_arima(). This
        method still returns a hardcoded (1,1,1,period) shape and is no longer
        called by fit(); left here in case external callers depended on it.
        """
        period = self._detect_seasonal_period(y)
        return (1, 1, 1, period) if period else None

    def _check_stationarity(self, y: pd.Series) -> bool:
        """Check if series is stationary using ADF test"""
        try:
            result = adfuller(y.dropna(), autolag='AIC')
            return bool(result[1] < 0.05)  # p-value < 0.05 means stationary
        except Exception:
            return False
