# Testing

LUCENT has two tiers of automated tests. Keep them separate so the
inner-loop stays fast.

## Fast unit tests (default)

Pure logic, no network, no database, no Redis. Run on every change.

```bash
cd backend
PYTHONPATH=. pytest tests/ -m "not integration"
```

Target: under 60 seconds.

Coverage areas:
- **Forecasting utilities** — frequency, data_validator, cross_validation, residual_tests, forecasters (ARIMA/ETS/Prophet — Prophet skips without CmdStan)
- **Services** — forecast_service, preprocessing_service, excel_exporter, report_exporter
- **Schemas** — forecast residual round-trip

## Integration tests

Boot the FastAPI app via `TestClient` with dependency overrides. Confirm
route mounting, auth guards, and serialization. Do not exercise the DB
or Redis.

```bash
cd backend
PYTHONPATH=. pytest tests/ -m integration
```

Markers are registered in `pytest.ini`.

## Everything

```bash
cd backend
PYTHONPATH=. pytest tests/
```

## Coverage report

Install once:

```bash
pip install pytest-cov
```

Run:

```bash
cd backend
PYTHONPATH=. pytest tests/ --cov=app --cov-report=term-missing
```

Targets (from spec 004):
- `app/forecasting/` ≥ 70% statement coverage
- `app/services/` ≥ 50%
- Overall: no hard gate yet

## Forecast accuracy benchmark

Not a pytest — a standalone script that runs each forecast method on
20 synthetic datasets and writes `specs/004-test-coverage-backfill/baseline.json`.

```bash
cd backend
PYTHONPATH=. python scripts/benchmark_forecasts.py
```

Current baseline (2026-04-18):
- ARIMA: avg MAPE 2.46%, median 1.90%
- ETS: avg MAPE 2.38%, median 1.25%
- Prophet: avg MAPE 3.96%, median 1.03%

The script is deterministic with seed=42 across runs. Future changes to
the forecasting pipeline can regress against this file.

To include Prophet, CmdStan must be installed:
```bash
pip install cmdstanpy
python -m cmdstanpy.install_cmdstan
```

## Writing new tests

- Put unit tests under `backend/tests/unit/<mirrored-app-path>/`
- Put integration tests under `backend/tests/integration/` with
  `pytestmark = pytest.mark.integration` at the top of the file
- Use the synthetic dataset generators in `backend/tests/data/synthetic.py`
  so test data stays reproducible and independent of external sources
