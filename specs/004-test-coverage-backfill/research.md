# Phase 0 — Research & Decisions

**Feature**: Test Coverage Backfill + Benchmarks
**Spec**: [spec.md](./spec.md)

Five design questions resolved.

---

## Decision 1 — Per-test DB isolation

**Decision**: Async savepoint per test inside an outer transaction that is rolled back on teardown.

Pattern:

```python
@pytest_asyncio.fixture
async def db_session():
    async with engine.connect() as conn:
        await conn.begin()
        async with AsyncSession(bind=conn, expire_on_commit=False) as session:
            await session.begin_nested()
            yield session
            await session.rollback()
        await conn.rollback()
```

**Rationale**: No schema creation/drop per test (fast). Each test sees an isolated, clean state. Data committed by the service under test is still visible inside the same connection but rolled back when the test exits.

**Alternative rejected**: truncating tables per test — too slow, risks breaking FKs.

---

## Decision 2 — Redis strategy

**Decision**: `fakeredis.FakeAsyncRedis` for unit tests; real Redis only for `integration` marker.

**Rationale**: `fakeredis` is a drop-in replacement that implements enough of Redis (strings, hashes, TTL) for our use. Zero network, deterministic, fast. Integration tests still hit real Redis to catch serialization/connection-pool quirks.

**Implementation**: In `tests/conftest.py`, monkeypatch `app.db.redis_client.get_redis` to return a `FakeAsyncRedis` instance; restore on teardown.

---

## Decision 3 — Prophet skip marker

**Decision**: File-level `pytestmark = pytest.mark.skipif(not cmdstan_available(), reason="...")`.

```python
import pytest

def _cmdstan_available() -> bool:
    try:
        import cmdstanpy
        cmdstanpy.cmdstan_path()
        return True
    except Exception:
        return False

pytestmark = pytest.mark.skipif(not _cmdstan_available(), reason="CmdStan not installed")
```

**Rationale**: One line at the top of `test_prophet.py` skips every test in the file cleanly. Runs in CI when CmdStan is available (Docker image), skips on dev machines without it.

---

## Decision 4 — Synthetic dataset library

**Decision**: Handwritten numpy generators in `backend/tests/data/synthetic.py`. No external library.

```python
def daily_with_weekly_seasonality(n=100, noise=1.0, seed=42):
    rng = np.random.default_rng(seed)
    t = np.arange(n)
    trend = 100 + 0.5 * t
    seasonal = 10 * np.sin(2 * np.pi * t / 7)
    return pd.Series(
        trend + seasonal + rng.standard_normal(n) * noise,
        index=pd.date_range("2024-01-01", periods=n, freq="D"),
    )

# 20 variants: mix of trend/no-trend, seasonal/non-seasonal, daily/weekly/monthly,
# with and without outliers, short (30 rows) and long (500 rows).
```

**Rationale**: Full control over properties. Known ground truth. Zero dependencies. Deterministic via seed.

**Alternative**: use `statsmodels` datasets — limited variety, real-world noise makes MAPE baseline less interpretable.

---

## Decision 5 — Coverage target

**Decision**:
- `backend/app/forecasting/`: 70% statement coverage (gate-ish but not a hard fail)
- `backend/app/services/`: 50% statement coverage
- Overall: no hard threshold for MVP

**Rationale**: Forecasting is algorithmic and deterministic — easy to hit 70%+. Services contain lots of I/O branches (Redis failures, DB failures, edge cases) that are harder and lower ROI to cover initially. Endpoint-layer coverage improves naturally via integration tests.

`pytest --cov=backend/app --cov-report=term-missing` will print the report; CI can fail on threshold later if desired.

---

## Testing Strategy

1. **Unit tests** (default, no marker) — pure logic, fast, no network:
   - Forecasters (ARIMA, ETS, Prophet)
   - Services (forecast, preprocessing, diagnostics, results, audit, excel_exporter, report_exporter)
   - Schema round-trips (residuals persistence)

2. **Integration tests** (`@pytest.mark.integration`):
   - FastAPI TestClient + real DB (transaction rollback)
   - Auth flow + endpoint shape
   - Export endpoints produce valid files

3. **Benchmark** (not pytest):
   - `scripts/benchmark_forecasts.py`
   - Produces deterministic `baseline.json`
   - Run manually; future CI job can compare against it

---

## Commands (for reference)

```bash
# Unit tests (fast)
cd backend && pytest tests/ -m "not integration" -v

# Integration tests (slower, needs DB + Redis)
cd backend && pytest tests/ -m integration -v

# With coverage
cd backend && pytest tests/ --cov=app --cov-report=term-missing -v

# Benchmark
cd backend && python scripts/benchmark_forecasts.py
```
