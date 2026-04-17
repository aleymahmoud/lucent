# Implementation Plan: Results & Diagnostics Parity

**Branch**: `002-results-and-diagnostics` | **Date**: 2026-04-17 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-results-and-diagnostics/spec.md`

## Summary

Close 17 parity gaps on the Results and Diagnostics pages. The critical fix is persisting real residuals (`model.resid`) through the full pipeline so the Diagnostics tab stops running statistical tests on synthetic normal data. Secondary high-impact fix is surfacing the cross-validation results that spec 001 already computes. The remaining 15 gaps are visualizations, tests, and export formats the old R app had. Scope limited to existing backend forecasting code, `results_service.py`, `diagnostics_service.py`, and their frontend counterparts; no new services or databases.

## Technical Context

**Language/Version**: Python 3.11 (backend), TypeScript 5 / Next.js 16 (frontend)
**Primary Dependencies**: FastAPI, SQLAlchemy, Pydantic v2, statsmodels, scipy, numpy, pandas; frontend uses Plotly.js (already in use), shadcn/ui, TanStack Query. New backend deps: `openpyxl` (already in pandas), optional `weasyprint` for PDF (graceful fallback to HTML if missing).
**Storage**: Upstash Redis (ForecastResultResponse incl. residuals, 1h TTL) + Neon PostgreSQL (`forecast_predictions.model_summary` JSON column gains a `residuals` key). No schema migration needed — JSON column already exists.
**Testing**: pytest for backend utilities (residual persistence, test calculations); manual walkthroughs per quickstart.md. No frontend tests.
**Target Platform**: Same as spec 001 — Windows Server 2022 local via PM2, production via Docker/Coolify.
**Project Type**: Web app (Next.js + FastAPI monorepo).
**Performance Goals**: Excel export < 2s single-entity; Diagnostics page load < 1.5s; model comparison 3 methods < 60s (blocking, matches the forecast loop).
**Constraints**: Backward-compat at the API boundary — old forecast records with no `residuals` must still be readable (show the "historical record" banner instead of crashing). No new external services; no migration requiring downtime.
**Scale/Scope**: ~10 source files modified, 4 new backend modules, 5 new/updated frontend components; ~500 lines of new logic.

## Constitution Check

No `.specify/memory/constitution.md` authored yet. Implicit gates: (1) CLAUDE.md rules about file ownership by domain + Discovery Before Creation anti-duplication protocol. (2) Every new shared utility must be registered in `docs/shared-registry.md`.

**Gate status**: PASS. No duplication — new modules (`residual_tests.py`, `excel_exporter.py`, `report_exporter.py`) implement capabilities that don't exist elsewhere.

## Project Structure

### Documentation (this feature)

```text
specs/002-results-and-diagnostics/
├── plan.md              # This file
├── spec.md              # 10 user stories + FRs + success criteria
├── research.md          # Phase 0 — residual persistence strategy, PDF lib choice, etc.
├── data-model.md        # Schema diffs: ForecastResultResponse.residuals, coefficient shape
├── contracts/           # Phase 1 — /results/export (Excel), /diagnostics/export (PDF/HTML)
├── quickstart.md        # Manual verification walkthroughs (one per user story)
└── tasks.md             # Phase 2 (/speckit-tasks output)
```

### Source Code (repository root)

```text
backend/
├── app/
│   ├── forecasting/
│   │   ├── arima.py                    # MODIFY: return full residuals array, SE, p-values
│   │   ├── ets.py                      # MODIFY: return full residuals array
│   │   ├── prophet_forecaster.py       # MODIFY: return full residuals array
│   │   ├── base.py                     # MODIFY: ForecastOutput gains coefficient detail shape
│   │   └── residual_tests.py           # NEW: Ljung-Box, Breusch-Pagan, Shapiro-Wilk helpers
│   ├── services/
│   │   ├── forecast_service.py         # MODIFY: persist residuals into result.model_summary
│   │   ├── diagnostics_service.py      # MODIFY: drop np.random.normal; use stored residuals
│   │   ├── results_service.py          # MODIFY: optional forecast-statistics enrichment
│   │   ├── excel_exporter.py           # NEW: multi-sheet .xlsx generation
│   │   └── report_exporter.py          # NEW: HTML + optional PDF generation
│   ├── schemas/
│   │   ├── forecast.py                 # MODIFY: residuals field, coefficient shape
│   │   └── diagnostics.py              # MODIFY: is_synthetic flag, test results shape
│   └── api/v1/endpoints/
│       ├── results.py                  # MODIFY: add /export/excel, enrich /summary
│       └── diagnostics.py              # MODIFY: add /export endpoint
│
frontend/
├── src/
│   ├── app/[tenant]/
│   │   ├── results/page.tsx            # MODIFY: add CV panel, stats panel, Excel button
│   │   └── diagnostics/page.tsx        # MODIFY: add residual-plot selector, tests, comparison UI
│   ├── components/results/
│   │   ├── ForecastChart.tsx           # MODIFY: plot-type selector + show-intervals + range slider
│   │   ├── ResultsTable.tsx            # MODIFY: 3 view modes
│   │   ├── ExportPanel.tsx             # MODIFY: Excel option
│   │   ├── CrossValidationPanel.tsx    # NEW: fold table + averaged metrics
│   │   └── ForecastStatsPanel.tsx      # NEW: mean/median/quartiles/IQR/avg width
│   └── components/diagnostics/
│       ├── ResidualChart.tsx           # MODIFY: add plot-type switcher
│       ├── ResidualTests.tsx           # NEW: Ljung-Box + BP + Shapiro-Wilk display
│       ├── CoefficientTable.tsx        # NEW: estimate + SE + z + p + significant
│       ├── ModelComparisonPanel.tsx    # NEW: checkboxes + run button + results table
│       ├── HistogramChart.tsx          # NEW: histogram + normal + KDE
│       ├── QQPlot.tsx                  # NEW: Q-Q plot
│       ├── ResidualTimeSeriesChart.tsx # NEW: scatter + ±σ bands
│       └── DiagnosticsExportPanel.tsx  # NEW: HTML / PDF export button
```

**Structure Decision**: Same monorepo as spec 001. Backend residual work concentrated in the three forecasters + `residual_tests.py`. Frontend adds new components per user story rather than bloating existing ones. All new utilities go through the shared registry.

## Phase 0 — Research & Decisions

Six open questions to resolve in [research.md](./research.md):

1. **Residual storage format**: list of floats in JSON vs binary blob. (Decision: list of floats, truncated to 2000 for safety.)
2. **Coefficient shape**: statsmodels returns SE via `model.bse` and p-values via `model.pvalues` — confirm both are reliable across `ARIMA`, `SARIMAX`, and `ExponentialSmoothing`.
3. **PDF library choice**: weasyprint (pure-Python, no Chrome) vs headless-chrome (heavier) vs HTML-only (skip PDF). Recommended: HTML-only for v1, PDF as follow-up if a dep is approved.
4. **Excel export library**: `openpyxl` (already a pandas sub-dep) vs `xlsxwriter`. Decision: `openpyxl` to avoid a new top-level dep.
5. **"Historical record" banner trigger**: use presence of `residuals` key in `model_summary` as the discriminator. Simple and works for both Redis and DB records.
6. **Old-data migration**: no retroactive fix for pre-existing records. Document the limitation; moving forward every new forecast has residuals.

## Phase 1 — Design Artifacts

- **[data-model.md](./data-model.md)** — ForecastResultResponse schema diff (adds `residuals`), coefficient object shape, diagnostics response `is_synthetic` flag.
- **[contracts/api-contracts.md](./contracts/api-contracts.md)** — new endpoints:
  - `GET /results/{id}/export/excel` — streams .xlsx.
  - `GET /results/batch/{batch_id}/export/excel` — multi-entity .xlsx.
  - `GET /diagnostics/{id}/export?format=html|pdf` — report export.
  - Response field additions on existing endpoints.
- **[quickstart.md](./quickstart.md)** — walkthrough per user story against synthetic benchmark datasets (reuse the set from spec 001's quickstart).

## Complexity Tracking

| Aspect | Decision |
|--------|----------|
| New backend modules | 3: `residual_tests.py`, `excel_exporter.py`, `report_exporter.py` — each has a single responsibility; avoids bloating `diagnostics_service.py` past 600 lines. |
| New frontend components | 8 — one per distinct concern (plots, tables, panels). Keeps existing components focused. |
| Database schema change | None — JSON column already exists. |
| Breaking API changes | None — all new fields are optional. Historical records still deserialise. |
| New dependencies | Zero new top-level deps. `openpyxl` is a transitive pandas dep already installed. PDF deferred to post-v1. |
