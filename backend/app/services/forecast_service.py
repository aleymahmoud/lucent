"""
Forecast Service - Forecasting operations and result management
"""
import pandas as pd
import numpy as np
from typing import Optional, List, Dict, Any, Tuple
from datetime import datetime
import json
import uuid
import logging

from sqlalchemy.ext.asyncio import AsyncSession

from app.db.redis_client import get_redis
from app.services.preprocessing_service import PreprocessingService
from app.services.snapshot_service import SnapshotService
from app.schemas.forecast import (
    ForecastMethod, ForecastStatus, ForecastFrequency,
    ForecastRequest, BatchForecastRequest,
    ForecastResultResponse, MetricsResponse, ModelSummaryResponse,
    PredictionResponse, MethodInfoResponse, AutoParamsResponse,
    DataCharacteristics, BatchForecastStatusResponse,
    CrossValidationResultResponse, FrequencyDetectionResponse,
    ForecastStatisticsResponse,
)
from app.forecasting import ARIMAForecaster, ETSForecaster, ProphetForecaster
from app.forecasting.frequency import detect_frequency as detect_freq, irregular_intervals_pct
from app.forecasting.data_validator import validate_for_method, DataValidationResult
from app.forecasting.cross_validation import run_cv as run_cv_engine, CVRunResult

logger = logging.getLogger(__name__)

# Redis configuration
REDIS_FORECAST_PREFIX = "forecast:"
REDIS_FORECAST_TTL = 3600  # 1 hour

# Strong references to background tasks to prevent GC from cancelling them
_background_tasks: set = set()


class ForecastService:
    """Service for running forecasts and managing results"""

    def __init__(self, tenant_id: str, user_id: Optional[str] = None, db: Optional[AsyncSession] = None):
        self.tenant_id = tenant_id
        self.user_id = user_id
        self.db = db
        self.preprocessing_service = PreprocessingService(tenant_id, user_id)

    # ============================================
    # Data Preparation
    # ============================================

    async def _get_forecast_data(
        self,
        dataset_id: str,
        entity_id: str,
        date_column: Optional[str] = None,
        value_column: Optional[str] = None,
        entity_column: Optional[str] = None,
        regressor_columns: Optional[List[str]] = None
    ) -> Tuple[Optional[pd.Series], Optional[str], Optional[pd.DataFrame]]:
        """
        Get time series data for forecasting.
        Falls back to raw data if no preprocessing exists.
        Returns (series, error, exog_df).

        Regressors: only columns explicitly listed in `regressor_columns` are used.
        No implicit auto-detection (US2). Missing columns return a validation error.
        """
        try:
            if entity_id and entity_id != "All Data":
                logger.info(f"_get_forecast_data: fetching entity={entity_id!r}, entity_column={entity_column!r}")
                df = await self.preprocessing_service.get_entity_data(
                    dataset_id, entity_id, entity_column
                )
            else:
                logger.info(f"_get_forecast_data: fetching full dataset for entity_id={entity_id!r}")
                df = await self.preprocessing_service.get_dataset_dataframe(dataset_id)

            if df is None:
                logger.warning(f"_get_forecast_data: df is None for dataset={dataset_id}")
                return None, "Dataset not found or expired", None

            logger.info(f"_get_forecast_data: got {len(df)} rows, columns={list(df.columns)}")

            if len(df) == 0:
                return None, "Dataset is empty", None

            if not date_column:
                date_column = self._detect_date_column(df)
            if not value_column:
                value_column = self._detect_value_column(df)

            if not date_column:
                return None, "Could not detect date column. Please specify date_column.", None
            if not value_column:
                return None, "Could not detect value column. Please specify value_column.", None

            if date_column not in df.columns:
                return None, f"Date column '{date_column}' not found in dataset", None
            if value_column not in df.columns:
                return None, f"Value column '{value_column}' not found in dataset", None

            df[date_column] = pd.to_datetime(df[date_column], errors='coerce')
            df = df.dropna(subset=[date_column, value_column])
            df = df.sort_values(date_column)

            df[value_column] = pd.to_numeric(df[value_column], errors='coerce')
            df = df.dropna(subset=[value_column])

            # Note: per-method min-data validation is done separately in run_forecast
            # after frequency is detected. Here we keep only a defensive minimum
            # so the function itself doesn't crash downstream.
            if len(df) < 2:
                return None, f"Insufficient data points ({len(df)}). Need at least 2 observations.", None

            series = pd.Series(
                df[value_column].values,
                index=pd.DatetimeIndex(df[date_column]),
                name=value_column
            )

            # Regressor handling — EXPLICIT ONLY (US2)
            exog_df = None
            if regressor_columns:
                missing = [c for c in regressor_columns if c not in df.columns]
                if missing:
                    return None, f"Regressor column(s) not found in dataset: {', '.join(missing)}", None

                available = [c for c in regressor_columns if c in df.columns]
                if available:
                    exog_df = df[[date_column] + available].copy()
                    exog_df.set_index(date_column, inplace=True)
                    for col in available:
                        exog_df[col] = pd.to_numeric(exog_df[col], errors='coerce')
                    col_means = exog_df.mean(numeric_only=True)
                    exog_df = exog_df.fillna(col_means)
                    exog_df = exog_df.dropna(axis=1, how='all')

            return series, None, exog_df

        except Exception as e:
            logger.error(f"Error preparing forecast data: {e}")
            return None, str(e), None

    # ============================================
    # Frequency Detection (public for endpoint)
    # ============================================

    async def detect_frequency(
        self,
        dataset_id: str,
        entity_id: Optional[str] = None,
        entity_column: Optional[str] = None,
        date_column: Optional[str] = None,
    ) -> FrequencyDetectionResponse:
        """Pre-flight frequency detection for UI hinting."""
        series, error, _ = await self._get_forecast_data(
            dataset_id,
            entity_id or "All Data",
            date_column=date_column,
            entity_column=entity_column,
        )
        if error or series is None:
            raise ValueError(error or "Could not load dataset")

        dates = series.index
        freq, period, median = detect_freq(dates)
        irregular = irregular_intervals_pct(dates)

        warnings: List[str] = []
        n = int(series.notna().sum())
        if n < 14 and freq == "D":
            warnings.append(f"Dataset has only {n} observations — weekly seasonality may be unreliable.")
        if n < 730 and freq == "D":
            warnings.append(
                f"Dataset has {n} observations. Yearly seasonality (if enabled) may invent patterns "
                f"(recommended >= 730 daily observations)."
            )
        if irregular > 10.0:
            warnings.append(
                f"Data has irregular intervals: {irregular:.1f}% of gaps deviate significantly from the median."
            )

        return FrequencyDetectionResponse(
            detected_frequency=freq,
            detected_seasonal_period=period,
            median_interval_days=round(median, 3),
            observation_count=n,
            irregular_intervals_pct=round(irregular, 2),
            warnings=warnings,
        )

    # ============================================
    # Forecast Execution
    # ============================================

    async def run_forecast(
        self,
        request: ForecastRequest,
        forecast_id: Optional[str] = None,
        forecast_history_id: Optional[str] = None,
    ) -> ForecastResultResponse:
        """Run a single forecast"""
        forecast_id = forecast_id or str(uuid.uuid4())

        # Initialize result
        result = ForecastResultResponse(
            id=forecast_id,
            dataset_id=request.dataset_id,
            entity_id=request.entity_id,
            method=request.method,
            status=ForecastStatus.RUNNING,
            progress=0,
            created_at=datetime.utcnow()
        )

        # Store initial status
        await self._store_result(result)

        try:
            # Get data
            result.progress = 10
            await self._store_result(result)

            logger.info(f"Forecast: entity_id={request.entity_id!r}, dataset={request.dataset_id}, method={request.method}, entity_column={request.entity_column!r}")

            series, error, exog_df = await self._get_forecast_data(
                request.dataset_id,
                request.entity_id,
                request.date_column,
                request.value_column,
                request.entity_column,
                request.regressor_columns
            )

            if error:
                logger.warning(f"Forecast data error for entity={request.entity_id!r}: {error}")
                result.status = ForecastStatus.FAILED
                result.error = error
                await self._store_result(result)
                return result

            logger.info(f"Forecast data OK: series_len={len(series)}, exog={exog_df.columns.tolist() if exog_df is not None else None}")

            # --- Frequency auto-detection (US1) ---
            detected_freq, detected_period, _ = detect_freq(series.index)
            result.detected_frequency = detected_freq
            result.detected_seasonal_period = detected_period

            effective_frequency = detected_freq
            if not request.frequency_auto_detect:
                # User wants manual frequency — honour it, but warn if mismatch
                effective_frequency = request.frequency.value
                if effective_frequency != detected_freq:
                    result.warnings.append(
                        f"Selected frequency {effective_frequency} does not match "
                        f"detected frequency {detected_freq}. Using {effective_frequency} as requested."
                    )
            # Propagate effective_frequency into the request for the forecaster factory
            request.frequency = ForecastFrequency(effective_frequency)

            # --- Per-method data validation (US3) ---
            prophet_settings = request.prophet_settings
            validation: DataValidationResult = validate_for_method(
                series,
                method=request.method.value,
                seasonal_period=detected_period if effective_frequency == detected_freq else 1,
                prophet_yearly=bool(prophet_settings.yearly_seasonality) if prophet_settings else False,
                prophet_weekly=bool(prophet_settings.weekly_seasonality) if prophet_settings else False,
                prophet_daily=bool(prophet_settings.daily_seasonality) if prophet_settings else False,
                dates=series.index,
            )
            if validation.blocking_error:
                logger.warning(f"Validation blocked forecast: {validation.blocking_error}")
                result.status = ForecastStatus.FAILED
                result.error = validation.blocking_error
                await self._store_result(result)
                return result
            result.warnings.extend(validation.warnings)

            # Only pass exog to Prophet (ARIMA/ETS don't support it in our implementation)
            use_exog = exog_df if (request.method == ForecastMethod.PROPHET and exog_df is not None and len(exog_df.columns) > 0) else None

            result.progress = 30
            await self._store_result(result)

            # Create forecaster (now receives effective frequency + seasonal_period)
            forecaster = self._create_forecaster(request, seasonal_period=detected_period)

            # Fit model
            result.progress = 50
            await self._store_result(result)

            forecaster.fit(series, exog=use_exog)

            result.progress = 70
            await self._store_result(result)

            # Generate predictions
            output = forecaster.predict(request.horizon, exog=use_exog)

            result.progress = 85
            await self._store_result(result)

            # Build predictions + metrics
            result.predictions = [
                PredictionResponse(
                    date=str(row['date'].date()) if hasattr(row['date'], 'date') else str(row['date']),
                    value=round(float(row['value']), 4),
                    lower_bound=round(float(row['lower_bound']), 4),
                    upper_bound=round(float(row['upper_bound']), 4)
                )
                for _, row in output.predictions.iterrows()
            ]

            result.metrics = MetricsResponse(**output.metrics)

            # Persist the full residuals array (truncated to last 2000) so the
            # Diagnostics page can compute real statistical tests.
            residuals_list: Optional[list] = None
            if output.residuals is not None:
                resids = np.asarray(output.residuals, dtype=float)
                resids = resids[np.isfinite(resids)]
                if len(resids) > 2000:
                    resids = resids[-2000:]
                residuals_list = [round(float(v), 6) for v in resids.tolist()]

            # Convert legacy dict coefficients into the new ModelCoefficient list shape,
            # preserving any already-list values as-is.
            raw_coeffs = output.model_summary.get('coefficients')
            coefficient_list = None
            if isinstance(raw_coeffs, list):
                coefficient_list = raw_coeffs
            elif isinstance(raw_coeffs, dict):
                coefficient_list = [
                    {"name": str(k), "estimate": float(v)} for k, v in raw_coeffs.items()
                ]

            result.model_summary = ModelSummaryResponse(
                method=request.method.value,
                parameters=output.model_summary.get('parameters', {}),
                coefficients=coefficient_list,
                diagnostics={
                    'residual_mean': round(float(np.mean(output.residuals)), 4) if output.residuals is not None else None,
                    'residual_std': round(float(np.std(output.residuals)), 4) if output.residuals is not None else None,
                    **{k: v for k, v in output.model_summary.items() if k not in ['method', 'parameters', 'coefficients']}
                },
                regressors_used=list(use_exog.columns) if use_exog is not None else None,
                residuals=residuals_list,
            )

            # --- Forecast Statistics (summary of predicted values) ---
            if result.predictions:
                values = np.array([p.value for p in result.predictions], dtype=float)
                widths = np.array([p.upper_bound - p.lower_bound for p in result.predictions], dtype=float)
                result.forecast_statistics = ForecastStatisticsResponse(
                    mean=round(float(np.mean(values)), 4),
                    median=round(float(np.median(values)), 4),
                    min=round(float(np.min(values)), 4),
                    max=round(float(np.max(values)), 4),
                    q25=round(float(np.percentile(values, 25)), 4),
                    q75=round(float(np.percentile(values, 75)), 4),
                    iqr=round(float(np.percentile(values, 75) - np.percentile(values, 25)), 4),
                    average_interval_width=round(float(np.mean(widths)), 4) if len(widths) else 0.0,
                )

            # --- Cross-validation (US5 of spec 001) ---
            if request.cross_validation and request.cross_validation.enabled:
                try:
                    cv_result = self._run_cross_validation(series, request, use_exog, detected_period)
                    result.cv_results = CrossValidationResultResponse(
                        folds=len(cv_result.folds),
                        method=cv_result.method,
                        metrics_per_fold=[
                            MetricsResponse(mae=f.mae, rmse=f.rmse, mape=f.mape)
                            for f in cv_result.folds
                        ],
                        average_metrics=MetricsResponse(
                            mae=cv_result.average_mae,
                            rmse=cv_result.average_rmse,
                            mape=cv_result.average_mape,
                        ),
                    )
                    if cv_result.reduced_folds:
                        result.warnings.append(
                            f"Requested {cv_result.requested_folds} CV folds; reduced to "
                            f"{len(cv_result.folds)} due to dataset size."
                        )
                except Exception as cv_err:
                    logger.warning(f"CV failed (non-blocking): {cv_err}")
                    result.warnings.append(f"Cross-validation failed: {cv_err}")

            result.progress = 100
            result.status = ForecastStatus.COMPLETED
            result.completed_at = datetime.utcnow()

            # Save predictions permanently to PostgreSQL (non-blocking)
            try:
                if self.db is not None and forecast_history_id:
                    await self._save_predictions_to_db(forecast_history_id, result)
            except Exception as db_err:
                logger.error(f"Failed to save predictions to DB (non-blocking): {db_err}")

        except Exception as e:
            logger.error(f"Forecast failed: {e}", exc_info=True)
            result.status = ForecastStatus.FAILED
            result.error = str(e)

        await self._store_result(result)
        return result

    def _run_cross_validation(
        self,
        series: pd.Series,
        request: ForecastRequest,
        exog: Optional[pd.DataFrame],
        seasonal_period: int,
    ) -> CVRunResult:
        """Execute CV using a forecaster factory closure."""
        cv = request.cross_validation

        def factory():
            return self._create_forecaster(request, seasonal_period=seasonal_period)

        return run_cv_engine(
            series=series,
            forecaster_factory=factory,
            folds=cv.folds,
            method=cv.method,
            initial_train_size=cv.initial_train_size,
            horizon=request.horizon,
            exog=exog,
        )

    async def start_batch_forecast(
        self,
        request: BatchForecastRequest
    ) -> BatchForecastStatusResponse:
        """Start a batch forecast — returns immediately, processes in background."""
        batch_id = str(uuid.uuid4())

        # Store initial batch status in Redis
        initial_status = BatchForecastStatusResponse(
            batch_id=batch_id,
            total=len(request.entity_ids),
            completed=0,
            failed=0,
            in_progress=len(request.entity_ids),
            status=ForecastStatus.RUNNING,
            results=[]
        )
        await self._store_batch_status(batch_id, initial_status)

        # Launch background task with strong reference to prevent GC
        import asyncio
        loop = asyncio.get_running_loop()
        task = loop.create_task(self._run_batch_background(batch_id, request))
        _background_tasks.add(task)
        task.add_done_callback(_background_tasks.discard)

        return initial_status

    async def _run_batch_background(
        self,
        batch_id: str,
        request: BatchForecastRequest
    ) -> None:
        """Background worker that processes batch entities one by one."""
        results: List[ForecastResultResponse] = []

        try:
            # Auto-detect entity column once for the whole batch
            entity_column = None
            try:
                df = await self.preprocessing_service.get_dataset_dataframe(request.dataset_id)
                if df is not None:
                    entity_column = self.preprocessing_service._detect_entity_column(df)
                    logger.info(f"Batch forecast: detected entity_column={entity_column!r}, entities={request.entity_ids}")
            except Exception as e:
                logger.warning(f"Batch: could not detect entity column: {e}")

            for i, entity_id in enumerate(request.entity_ids):
                single_request = ForecastRequest(
                    dataset_id=request.dataset_id,
                    entity_id=entity_id,
                    entity_column=entity_column or request.entity_column,
                    date_column=request.date_column,
                    value_column=request.value_column,
                    method=request.method,
                    horizon=request.horizon,
                    frequency=request.frequency,
                    frequency_auto_detect=request.frequency_auto_detect,
                    confidence_level=request.confidence_level,
                    arima_settings=request.arima_settings,
                    ets_settings=request.ets_settings,
                    prophet_settings=request.prophet_settings,
                    cross_validation=request.cross_validation,
                    regressor_columns=request.regressor_columns
                )

                result = await self.run_forecast(single_request)
                results.append(result)

                # Update batch status in Redis after each entity
                completed = sum(1 for r in results if r.status == ForecastStatus.COMPLETED)
                failed = sum(1 for r in results if r.status == ForecastStatus.FAILED)
                remaining = len(request.entity_ids) - len(results)

                batch_status = BatchForecastStatusResponse(
                    batch_id=batch_id,
                    total=len(request.entity_ids),
                    completed=completed,
                    failed=failed,
                    in_progress=remaining,
                    status=ForecastStatus.RUNNING if remaining > 0 else (
                        ForecastStatus.COMPLETED if completed > 0 else ForecastStatus.FAILED
                    ),
                    results=results
                )
                await self._store_batch_status(batch_id, batch_status)

            logger.info(f"Batch {batch_id} finished: {sum(1 for r in results if r.status == ForecastStatus.COMPLETED)}/{len(results)} completed")

        except Exception as e:
            # Top-level handler: mark batch as FAILED so it doesn't stay stuck as "running"
            logger.error(f"Batch {batch_id} crashed: {e}", exc_info=True)
            failed_status = BatchForecastStatusResponse(
                batch_id=batch_id,
                total=len(request.entity_ids),
                completed=sum(1 for r in results if r.status == ForecastStatus.COMPLETED),
                failed=len(request.entity_ids) - sum(1 for r in results if r.status == ForecastStatus.COMPLETED),
                in_progress=0,
                status=ForecastStatus.FAILED,
                results=results
            )
            await self._store_batch_status(batch_id, failed_status)

    async def _store_batch_status(self, batch_id: str, status: BatchForecastStatusResponse) -> None:
        """Store batch forecast status in Redis."""
        try:
            redis = await get_redis()
            if redis is None:
                return
            key = f"forecast_batch:{batch_id}"
            data = status.model_dump(mode='json')
            await redis.set(key, json.dumps(data, default=str), ex=REDIS_FORECAST_TTL)
        except Exception as e:
            logger.error(f"Error storing batch status: {e}")

    async def get_batch_status(self, batch_id: str) -> Optional[BatchForecastStatusResponse]:
        """Get batch forecast status from Redis."""
        try:
            redis = await get_redis()
            if redis is None:
                return None
            key = f"forecast_batch:{batch_id}"
            data = await redis.get(key)
            if data:
                if isinstance(data, bytes):
                    data = data.decode('utf-8')
                return BatchForecastStatusResponse(**json.loads(data))
            return None
        except Exception as e:
            logger.error(f"Error getting batch status: {e}")
            return None

    # ============================================
    # Auto Parameter Detection
    # ============================================

    async def auto_detect_parameters(
        self,
        method: ForecastMethod,
        dataset_id: str,
        entity_id: str
    ) -> AutoParamsResponse:
        """Auto-detect optimal parameters for a method"""
        series, error, _ = await self._get_forecast_data(dataset_id, entity_id)
        if error:
            raise ValueError(error)

        frequency = self._detect_frequency(series)

        if method == ForecastMethod.ARIMA:
            params = ARIMAForecaster.auto_detect_params(series, frequency)
        elif method == ForecastMethod.ETS:
            params = ETSForecaster.auto_detect_params(series, frequency)
        else:  # Prophet
            params = ProphetForecaster.auto_detect_params(series, frequency)

        # Analyze data characteristics
        characteristics = self._analyze_data_characteristics(series)

        return AutoParamsResponse(
            method=method,
            recommended_params=params,
            data_characteristics=characteristics
        )

    # ============================================
    # Forecaster Factory
    # ============================================

    def _create_forecaster(self, request: ForecastRequest, seasonal_period: int = 1):
        """Create appropriate forecaster based on method.

        `seasonal_period` comes from frequency auto-detection and is used to
        set sensible defaults for seasonal-aware models.
        """
        frequency = request.frequency.value

        if request.method == ForecastMethod.ARIMA:
            settings = request.arima_settings
            if settings and not settings.auto:
                # Manual mode — honour user overrides
                return ARIMAForecaster(
                    frequency=frequency,
                    confidence_level=request.confidence_level,
                    auto=False,
                    order=(settings.p or 1, settings.d or 1, settings.q or 1),
                    seasonal_order=(
                        settings.P or 0,
                        settings.D or 0,
                        settings.Q or 0,
                        settings.s or seasonal_period
                    ) if (settings.s or seasonal_period > 1) else None
                )
            return ARIMAForecaster(
                frequency=frequency,
                confidence_level=request.confidence_level,
                auto=True
            )

        elif request.method == ForecastMethod.ETS:
            settings = request.ets_settings
            if settings and not settings.auto:
                return ETSForecaster(
                    frequency=frequency,
                    confidence_level=request.confidence_level,
                    auto=False,
                    trend=settings.trend,
                    seasonal=settings.seasonal,
                    seasonal_periods=settings.seasonal_periods or (seasonal_period if seasonal_period > 1 else None),
                    damped_trend=settings.damped_trend
                )
            # Auto mode — supply detected seasonal period as hint
            return ETSForecaster(
                frequency=frequency,
                confidence_level=request.confidence_level,
                auto=True,
                seasonal_periods=seasonal_period if seasonal_period > 1 else None
            )

        else:  # Prophet
            settings = request.prophet_settings
            if settings:
                return ProphetForecaster(
                    frequency=frequency,
                    confidence_level=request.confidence_level,
                    changepoint_prior_scale=settings.changepoint_prior_scale,
                    seasonality_prior_scale=settings.seasonality_prior_scale,
                    seasonality_mode=settings.seasonality_mode,
                    yearly_seasonality=settings.yearly_seasonality,
                    weekly_seasonality=settings.weekly_seasonality,
                    daily_seasonality=settings.daily_seasonality
                )
            return ProphetForecaster(
                frequency=frequency,
                confidence_level=request.confidence_level
            )

    # ============================================
    # Result Storage
    # ============================================

    async def _store_result(self, result: ForecastResultResponse) -> None:
        """Store forecast result in Redis"""
        try:
            redis = await get_redis()
            if redis is None:
                return

            key = f"{REDIS_FORECAST_PREFIX}{result.id}"
            data = result.model_dump(mode='json')
            await redis.set(key, json.dumps(data, default=str), ex=REDIS_FORECAST_TTL)

        except Exception as e:
            logger.error(f"Error storing forecast result: {e}")

    async def _save_predictions_to_db(
        self,
        forecast_history_id: str,
        result: ForecastResultResponse,
    ) -> None:
        """Persist forecast predictions to PostgreSQL for permanent storage."""
        from app.models import ForecastPrediction

        prediction = ForecastPrediction(
            id=str(uuid.uuid4()),
            tenant_id=self.tenant_id,
            forecast_history_id=forecast_history_id,
            entity_id=result.entity_id or "unknown",
            entity_name=None,
            predicted_values=[
                {"date": p.date, "value": p.value, "lower_bound": p.lower_bound, "upper_bound": p.upper_bound}
                for p in (result.predictions or [])
            ],
            metrics=result.metrics.model_dump() if result.metrics else None,
            model_summary=result.model_summary.model_dump() if result.model_summary else None,
            cv_results=result.cv_results.model_dump() if result.cv_results else None,
        )
        self.db.add(prediction)
        await self.db.flush()
        logger.info(
            "Saved prediction to DB: forecast_history_id=%s entity=%s",
            forecast_history_id,
            result.entity_id,
        )

    async def get_forecast_status(self, forecast_id: str) -> Optional[ForecastResultResponse]:
        """Get forecast status/result from Redis"""
        try:
            redis = await get_redis()
            if redis is None:
                return None

            key = f"{REDIS_FORECAST_PREFIX}{forecast_id}"
            data = await redis.get(key)

            if data:
                if isinstance(data, bytes):
                    data = data.decode('utf-8')
                return ForecastResultResponse(**json.loads(data))
            return None

        except Exception as e:
            logger.error(f"Error getting forecast status: {e}")
            return None

    # ============================================
    # Method Information
    # ============================================

    def get_available_methods(self) -> List[MethodInfoResponse]:
        """Get information about available forecasting methods"""
        return [
            MethodInfoResponse(
                id="arima",
                name="ARIMA",
                description="AutoRegressive Integrated Moving Average - Best for data with clear trends and autocorrelation patterns. Handles both stationary and non-stationary time series.",
                supports_seasonality=True,
                supports_exogenous=True,
                default_settings={
                    'auto': True,
                    'p': 1, 'd': 1, 'q': 1
                }
            ),
            MethodInfoResponse(
                id="ets",
                name="ETS (Exponential Smoothing)",
                description="Error-Trend-Seasonality model - Best for data with clear level, trend, and seasonal patterns. Uses weighted averages of past observations.",
                supports_seasonality=True,
                supports_exogenous=False,
                default_settings={
                    'auto': True,
                    'trend': 'add',
                    'seasonal': None,
                    'damped_trend': False
                }
            ),
            MethodInfoResponse(
                id="prophet",
                name="Prophet",
                description="Facebook's forecasting model - Best for business time series with strong seasonal effects, holidays, and missing data. Handles outliers well.",
                supports_seasonality=True,
                supports_exogenous=True,
                default_settings={
                    'changepoint_prior_scale': 0.05,
                    'seasonality_mode': 'additive',
                    'yearly_seasonality': True,
                    'weekly_seasonality': True
                }
            )
        ]

    # ============================================
    # Helper Methods
    # ============================================

    def _detect_date_column(self, df: pd.DataFrame) -> Optional[str]:
        """Auto-detect date column"""
        date_keywords = ["date", "time", "timestamp", "period", "day", "month", "year"]

        # First, check column names
        for col in df.columns:
            if any(kw in col.lower() for kw in date_keywords):
                return col

        # Then, check column types
        for col in df.columns:
            if df[col].dtype == 'datetime64[ns]':
                return col
            # Try to parse as date
            try:
                pd.to_datetime(df[col].head(10), errors='raise')
                return col
            except Exception:
                continue

        return None

    def _detect_value_column(self, df: pd.DataFrame) -> Optional[str]:
        """Auto-detect value column"""
        value_keywords = ["value", "sales", "amount", "quantity", "demand", "price",
                         "revenue", "volume", "count", "total", "sum"]

        numeric_cols = df.select_dtypes(include=[np.number]).columns.tolist()

        # First, check for keyword matches in numeric columns
        for col in numeric_cols:
            if any(kw in col.lower() for kw in value_keywords):
                return col

        # Return first numeric column that's not an ID or index
        for col in numeric_cols:
            if not any(kw in col.lower() for kw in ['id', 'index', 'key']):
                return col

        return numeric_cols[0] if numeric_cols else None

    def _detect_frequency(self, series: pd.Series) -> str:
        """Detect data frequency from time series"""
        if len(series) < 2:
            return 'D'

        try:
            # Calculate median time difference
            time_diffs = series.index.to_series().diff().dropna()
            median_diff = time_diffs.median()

            if median_diff.days >= 28:
                return 'M'
            elif median_diff.days >= 7:
                return 'W'
            else:
                return 'D'
        except Exception:
            return 'D'

    def _analyze_data_characteristics(self, series: pd.Series) -> Dict[str, Any]:
        """Analyze time series characteristics"""
        y = series.dropna()

        # Basic statistics
        characteristics = {
            'length': len(y),
            'mean': round(float(y.mean()), 4),
            'std': round(float(y.std()), 4),
            'min': round(float(y.min()), 4),
            'max': round(float(y.max()), 4),
            'has_missing': bool(series.isna().any()),
            'missing_count': int(series.isna().sum())
        }

        # Trend detection
        if len(y) >= 2:
            first_quarter = y[:len(y)//4].mean()
            last_quarter = y[-len(y)//4:].mean()
            if last_quarter > first_quarter * 1.1:
                characteristics['trend'] = 'increasing'
            elif last_quarter < first_quarter * 0.9:
                characteristics['trend'] = 'decreasing'
            else:
                characteristics['trend'] = 'stationary'
        else:
            characteristics['trend'] = 'unknown'

        # Stationarity check
        try:
            from statsmodels.tsa.stattools import adfuller
            result = adfuller(y, autolag='AIC')
            characteristics['is_stationary'] = bool(result[1] < 0.05)
            characteristics['adf_pvalue'] = round(float(result[1]), 4)
        except Exception:
            characteristics['is_stationary'] = None

        # Seasonality detection
        characteristics['seasonality_detected'] = False
        characteristics['seasonality_period'] = None

        try:
            for period in [7, 12, 30, 52]:
                if len(y) >= 2 * period:
                    autocorr = pd.Series(y.values).autocorr(lag=period)
                    if autocorr and autocorr > 0.3:
                        characteristics['seasonality_detected'] = True
                        characteristics['seasonality_period'] = period
                        break
        except Exception:
            pass

        return characteristics
