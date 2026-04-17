# Implementation Plan: Fix Forecast Accuracy

**Branch**: `001-fix-forecast-accuracy` | **Date**: 2026-04-16 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-fix-forecast-accuracy/spec.md`

## Summary

Fix the thirteen concrete bugs and parity gaps causing "extremely bad" forecast accuracy in LUCENT, prioritized by impact on user-visible results. The root causes are (1) silent frequency mismatches that change the forecast problem entirely, (2) indiscriminate regressor auto-detection that poisons Prophet with ID columns, (3) no per-method minimum-data validation, (4) no ARIMA failure fallback, and (5) an unimplemented cross-validation pipeline that makes accuracy unmeasurable. Fixes are scoped to the backend `app/forecasting/` and `app/services/forecast_service.py` plus small frontend changes in `frontend/src/components/forecast/`.

## Technical Context

**Language/Version**: Python 3.11 (backend), TypeScript 5 / Next.js 16 (frontend)
**Primary Dependencies**: FastAPI 0.109, SQLAlchemy 2.0, Pydantic v2, statsmodels (ARIMA/SARIMAX/ETS), facebook/prophet, numpy, pandas; frontend uses shadcn/ui + Zustand + TanStack Query
**Storage**: Upstash Redis (forecast progress + 1h cache), Neon PostgreSQL (`forecast_history` audit trail + `forecast_predictions` permanent results)
**Testing**: pytest (backend, not heavily used today); manual end-to-end via PM2-managed local services; no frontend test harness
**Target Platform**: Windows Server 2022 deployed behind PM2 (port 3840 frontend, 8000 backend); production path via GitHub -> Coolify -> Docker
**Project Type**: Web application (Next.js frontend + FastAPI backend in monorepo)
**Performance Goals**: Single-entity forecast returns in < 10 seconds for typical datasets (< 1000 rows); batch of 50 entities completes within 5 minutes; UI remains responsive during runs via Redis-backed polling.
**Constraints**: Changes must be backward compatible — existing forecast history records must still deserialise; Redis TTL for in-flight forecasts remains 1 hour; no new external service dependencies; no Celery migration (current inline execution pattern is acceptable).
**Scale/Scope**: ~12 source files to modify; ~400 lines of new logic (CV engine is the largest single module); frontend changes are additive (new warning banner component, updated result tab).

## Constitution Check

No `.specify/memory/constitution.md` has been authored for this project. The implicit gate is the existing `CLAUDE.md` plus the "Discovery Before Creation" anti-duplication protocol: every new helper must be checked against `backend/app/core/`, `backend/app/services/`, and existing utilities before being written. Any new shared utility must be registered in `docs/shared-registry.md`.

**Gate status**: PASS (pending utility discovery per phase).

## Project Structure

### Documentation (this feature)

```text
specs/001-fix-forecast-accuracy/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 — decisions on CV algorithm, detection thresholds
├── data-model.md        # Phase 1 — schema diffs for ForecastRequest/Result/CVResult
├── contracts/           # Phase 1 — API diffs for /forecast/run, /forecast/detect-frequency
├── quickstart.md        # Phase 1 — manual verification walkthrough
└── tasks.md             # Phase 2 (/speckit-tasks output)
```

### Source Code (repository root)

```text
backend/
├── app/
│   ├── forecasting/
│   │   ├── base.py                 # MAY update: add min-data helper
│   │   ├── arima.py                # MODIFY: fallback chain, joint seasonal search, stricter ACF
│   │   ├── ets.py                  # MODIFY: seasonal period from detected frequency
│   │   ├── prophet_forecaster.py   # MODIFY: reject auto-detected regressors
│   │   └── cross_validation.py     # NEW: rolling + expanding window CV engine
│   ├── services/
│   │   └── forecast_service.py     # MODIFY: remove regressor auto-detect, wire frequency auto-detect, add min-data gate, warning collection, CV integration
│   ├── schemas/
│   │   └── forecast.py             # MODIFY: add detected_frequency, warnings[], populate cv_results
│   └── api/v1/endpoints/
│       └── forecast.py             # MODIFY: add /forecast/detect-frequency endpoint; return warnings
│
frontend/
├── src/
│   ├── app/[tenant]/forecast/page.tsx       # MODIFY: auto-detect UX, warnings display
│   └── components/forecast/
│       ├── ForecastSettings.tsx             # MODIFY: auto-detect toggle, show detected frequency
│       ├── ForecastWarnings.tsx             # NEW: pre-run warnings panel
│       ├── ForecastResults.tsx              # MODIFY: side-by-side in-sample vs CV metrics
│       └── CrossValidationSettings.tsx      # No code change; confirm wired end-to-end
```

**Structure Decision**: Web application monorepo. All new backend logic lives in `backend/app/forecasting/` and `backend/app/services/forecast_service.py`. The one new Python module is `cross_validation.py` (co-located with the existing forecasters). The one new React component is `ForecastWarnings.tsx` (co-located with existing forecast components).

## Phase 0 — Research & Decisions

The following open questions should be resolved in `research.md` before implementation begins:

1. **Frequency detection algorithm**: median time delta vs mode vs hybrid. The old R app used modal difference with explicit handling for 28-31 day months. Decide on a single canonical algorithm matching those rules.
2. **ARIMA joint seasonal search bounds**: how many (P,D,Q) combinations to test. The old R app uses `max.P=2, max.Q=2, max.D=1` — total 18 combos. Decide: match R exactly or tune down for Python performance.
3. **Cross-validation fold-size rule**: `h_cv = min(12, floor(n * 0.15))` from old R. Decide whether to keep the same rule, make it user-configurable, or use a different default.
4. **Rolling vs expanding window implementation**: confirm `walk-forward` semantics (train-set start is fixed vs sliding).
5. **Minimum-data alternative-method recommendation**: on failure, which method to suggest? Rule: if data is too short for seasonal ARIMA but long enough for ETS, suggest ETS; if too short for everything seasonal, suggest Prophet with seasonality off.
6. **Warning delivery mechanism**: (a) return warnings in the POST /run response and render on results tab; (b) separate GET /forecast/check endpoint called before submit; (c) both. Decide the API shape.

## Phase 1 — Design Artifacts

### data-model.md (to produce)

- `ForecastRequest.frequency_auto_detect: bool = True` (new default)
- `ForecastRequest.regressor_columns: List[str] = []` (remove implicit detection)
- `ForecastResultResponse.detected_frequency: Optional[str]` (new)
- `ForecastResultResponse.warnings: List[str] = []` (new)
- `ForecastResultResponse.cv_results: Optional[CrossValidationResultResponse]` (populate it)
- `CrossValidationResultResponse.folds: int`, `method: str`, `metrics_per_fold: List[Dict]`, `average_metrics: Dict` (already in schema, confirm populated)

### contracts/ (to produce)

- `POST /forecast/run` — response adds `detected_frequency`, `warnings[]`, `cv_results` (already in schema); request adds `frequency_auto_detect`.
- `POST /forecast/detect-frequency` (new) — given dataset_id + entity_id, returns detected frequency and warnings without running a forecast; used by the UI to show "Detected: Daily" next to the frequency dropdown.
- `POST /forecast/validate` (optional, merges into /run) — pre-flight check that returns warnings and blocking errors; decide in Phase 0 if we do this separately.

### quickstart.md (to produce)

Manual verification walkthrough that exercises each user story end-to-end. Each story has a scripted dataset (synthetic, generated by a small Python helper) and expected output.

## Complexity Tracking

No constitutional violations. One new module (`cross_validation.py`) is justified because it's a distinct algorithm with its own testable surface; inlining it into `forecast_service.py` would bloat that service past 1000 lines. The frontend has one new component (`ForecastWarnings.tsx`); it's a focused UI concern that warrants isolation.

| Aspect | Decision |
|--------|----------|
| New backend module | `cross_validation.py` — justified by single-responsibility |
| New frontend component | `ForecastWarnings.tsx` — justified by reuse across ForecastSettings pre-run view and Results tab post-run view |
| New shared utility | None planned; reuse existing `_detect_frequency`, `_detect_date_column`, `_detect_value_column` helpers in `forecast_service.py` |
| Database schema change | None; `cv_results` column already exists in `forecast_predictions` |
