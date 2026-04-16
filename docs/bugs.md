# LUCENT Bug Tracker

> Maintained by Farida (QA / Code Reviewer).
> All bugs found during code review are logged here. Severity: Critical > High > Medium > Low.

---

## Open Bugs

---

### [BUG-001] asyncio.create_task loses the task reference -- background work silently dies
- **Severity**: Critical
- **Location**: `backend/app/services/forecast_service.py`, line 287
- **Found in**: Nabil
- **Description**: `asyncio.create_task(self._run_batch_background(...))` is called but the returned Task object is never stored. Python holds only a weak reference to unawaited tasks. If the GC runs before the task completes, the task is silently cancelled with no error logged and no Redis update. The batch status stays `running` forever until TTL expires and the frontend polls indefinitely.
- **Expected**: Store the returned task in a module-level set so it stays alive, and discard it via a done-callback when complete.
- **Fix**: Use `_background_tasks: set = set()` at module level. Then: `task = asyncio.create_task(...); _background_tasks.add(task); task.add_done_callback(_background_tasks.discard)`. Escalate to Reem if a proper task-registry service is preferred.

---

### [BUG-002] asyncio.create_task may raise RuntimeError on Windows with WindowsSelectorEventLoopPolicy
- **Severity**: Critical
- **Location**: `backend/app/main.py` line 10 + `backend/app/services/forecast_service.py` line 287
- **Found in**: Nabil / Tarek
- **Description**: `main.py` sets `asyncio.WindowsSelectorEventLoopPolicy()` for Windows (the active deployment OS). On some Uvicorn+Windows reload configurations `asyncio.create_task` can be called from a context where the current event loop is not the running loop, producing `RuntimeError: no current event loop`. Additionally, the endpoint docstring already states the batch endpoint was designed to dispatch to Celery -- using `create_task` directly is an architectural deviation.
- **Expected**: Use `asyncio.get_running_loop().create_task(...)` as the immediate fix. Long-term: move batch processing to Celery as originally designed.
- **Fix**: Replace `asyncio.create_task(...)` with `asyncio.get_running_loop().create_task(...)`. Raise with Reem to schedule the Celery migration.

---

### [BUG-003] Batch Redis key can expire before a long-running batch completes
- **Severity**: High
- **Location**: `backend/app/services/forecast_service.py`, lines 347-357
- **Found in**: Nabil
- **Description**: `REDIS_FORECAST_TTL = 3600` (1 hour) is shared between individual forecast results and batch status keys. A 50-entity batch on slow hardware can take more than 1 hour. If one entity takes longer than 1 hour to process, the batch key written after the previous entity completion will expire before `_store_batch_status` is called again. The frontend then receives a 404 on the next poll.
- **Expected**: Use a longer TTL for batch operations.
- **Fix**: Add `REDIS_BATCH_TTL = 4 * 3600` and use it in `_store_batch_status` instead of `REDIS_FORECAST_TTL`.

---

### [BUG-004] `get_batch_status` uses `**json.loads(data)` constructor instead of `model_validate`
- **Severity**: High
- **Location**: `backend/app/services/forecast_service.py`, line 370 (and line 509 for single forecast)
- **Found in**: Nabil
- **Description**: `BatchForecastStatusResponse(**json.loads(data))` passes a raw dict to the Pydantic v2 constructor. For nested models -- the `results` list contains full `ForecastResultResponse` objects with datetime fields and nested sub-models -- the idiomatic Pydantic v2 path is `model_validate`, not `**kwargs`. Using `**kwargs` bypasses Pydantic v2 validation hooks and can behave unexpectedly for complex nested structures. The same issue exists at line 509 for `ForecastResultResponse`.
- **Expected**: Use `model_validate` for all Redis deserialization.
- **Fix**: `return BatchForecastStatusResponse.model_validate(json.loads(data))` at line 370. `return ForecastResultResponse.model_validate(json.loads(data))` at line 509.

---

### [BUG-005] Dead bytes-decode branch -- `decode_responses=True` makes it unreachable
- **Severity**: Medium
- **Location**: `backend/app/services/forecast_service.py`, lines 368-369 and 507-508
- **Found in**: Nabil
- **Description**: Both `get_batch_status` and `get_forecast_status` check `isinstance(data, bytes)` before decoding. The Redis client is initialized with `decode_responses=True` (`redis_client.py` line 24), so the client always returns `str`, never `bytes`. The bytes branch is dead code and misleads future maintainers.
- **Expected**: Remove the dead decode branch.
- **Fix**: Delete the `isinstance(data, bytes)` guard blocks in both methods.

---

### [BUG-006] Frontend batch polling has no unmount cleanup -- network and memory leak
- **Severity**: High
- **Location**: `frontend/src/app/[tenant]/forecast/page.tsx`, lines 266-292
- **Found in**: Yoki
- **Description**: The `poll` function calls `setTimeout(poll, 3000)` recursively but the returned handle is never stored. If the user navigates away while the batch is running, the component unmounts but: (1) the timeout fires every 3 seconds indefinitely; (2) each fire sends a real network request via `api.get`; (3) each fire calls `setBatchResult`, `setIsRunning`, and `setActiveTab` on the unmounted component. `ForecastProgress.tsx` solves this correctly with `pollTimerRef` and a useEffect cleanup -- the same pattern must be applied here.
- **Expected**: Store the timeout handle in a `useRef` and clear it on unmount.
- **Fix**: Refactor batch polling into a `useEffect` that returns a cleanup function clearing the stored timer ref, mirroring `ForecastProgress.tsx`.

---

### [BUG-007] Batch polling catch block swallows all errors with no user feedback
- **Severity**: Medium
- **Location**: `frontend/src/app/[tenant]/forecast/page.tsx`, lines 288-291
- **Found in**: Yoki
- **Description**: The catch block only calls `setIsRunning(false)`. A 404 (batch key expired), a 401 (session expired), or a network timeout all cause the spinner to silently vanish. The user cannot distinguish the batch completing from polling silently breaking.
- **Expected**: Transient errors should be retried up to a maximum count. Definitive errors must display a toast.
- **Fix**: Track a retry counter. On transient errors continue polling up to MAX_POLL_RETRIES. On persistent failure call `toast.error` explaining what happened.

---

### [BUG-008] Batch final status is COMPLETED even when some entities failed -- missing PARTIAL status
- **Severity**: High
- **Location**: `backend/app/services/forecast_service.py`, lines 338-341
- **Found in**: Nabil
- **Description**: When `remaining == 0 and completed > 0`, the batch status is always `COMPLETED` regardless of whether any entities also failed. There is no `PARTIAL` status in `ForecastStatus`. A batch where 2 of 10 entities failed returns `status: "completed"`. Downstream consumers treating `completed` as full success will silently miss partial failures.
- **Expected**: Add `PARTIAL = "partial"` to `ForecastStatus` and apply it when `completed > 0 and failed > 0`.
- **Fix**: Add `PARTIAL = "partial"` to `ForecastStatus` enum in `schemas/forecast.py`. Update `_run_batch_background` status logic to: RUNNING if remaining > 0, PARTIAL if completed > 0 and failed > 0, COMPLETED if completed > 0 and failed == 0, FAILED if completed == 0.

---

### [BUG-009] `frequencyMap` defined inline in `handleRunForecast` -- should be a shared constant
- **Severity**: Medium (Duplication -- near-blocking)
- **Location**: `frontend/src/app/[tenant]/forecast/page.tsx`, line 237
- **Found in**: Yoki
- **Description**: `const frequencyMap = { daily: "D", weekly: "W", monthly: "M" }` is defined inside the callback body. This UI-label-to-API-value mapping is domain logic that belongs in shared constants. No canonical version exists in `docs/shared-registry.md`. Per the anti-duplication protocol it must be registered before it propagates to other components.
- **Expected**: Extract to `frontend/src/lib/constants/forecast.ts`, export as `FREQUENCY_MAP`, and register in the shared registry.
- **Fix**: Create `frontend/src/lib/constants/forecast.ts` with `export const FREQUENCY_MAP = { daily: "D", weekly: "W", monthly: "M" } as const`. Import in `page.tsx`. Register in `docs/shared-registry.md`.

---

### [BUG-010] `REDIS_FORECAST_PREFIX` and `REDIS_FORECAST_TTL` defined in two backend files -- BLOCKING DUPLICATE
- **Severity**: Medium (Duplication -- BLOCKING)
- **Location**: `backend/app/services/forecast_service.py` lines 26-27 AND `backend/app/api/v1/endpoints/forecast.py` lines 25-26
- **Found in**: Nabil
- **Description**: Both files define identical constants with identical values. The endpoint file defines them but never uses `REDIS_FORECAST_TTL` and never uses `REDIS_FORECAST_PREFIX` -- all Redis operations are delegated to the service layer. These are orphaned duplicates. Per the anti-duplication protocol this is a blocking issue and the task is not complete until resolved.
- **Expected**: Remove the constant definitions from `backend/app/api/v1/endpoints/forecast.py`.
- **Fix**: Delete lines 25-26 from `backend/app/api/v1/endpoints/forecast.py`.

---

### [BUG-011] `ForecastResult` and `BatchForecastResult` interfaces defined in two frontend files -- BLOCKING DUPLICATE
- **Severity**: Medium (Duplication -- BLOCKING)
- **Location**: `frontend/src/app/[tenant]/forecast/page.tsx` lines 56-98 AND `frontend/src/components/forecast/BatchForecastResults.tsx` lines 34-63
- **Found in**: Yoki
- **Description**: Both files independently define `interface ForecastResult` and `interface BatchForecastResult`. The `Metrics` sub-interface in `BatchForecastResults.tsx` omits `aic` and `bic` (present in `page.tsx`), proving the definitions have already drifted. Per the anti-duplication protocol this is a blocking issue.
- **Expected**: Move both interfaces to `frontend/src/types/forecast.ts` and import from there in both files. Register in `docs/shared-registry.md`.
- **Fix**: Create `frontend/src/types/forecast.ts` with canonical definitions. Delete local redefinitions. Update imports. Register in the shared registry.

---

### [BUG-012] `onStatusUpdate` prop typed as `any` -- violates no-any rule
- **Severity**: Low
- **Location**: `frontend/src/components/forecast/ForecastProgress.tsx`, line 14
- **Found in**: Yoki
- **Description**: `onStatusUpdate?: (result: any) => void` uses the `any` type, violating the project TypeScript standard which requires `unknown` with type guards or a concrete type.
- **Expected**: `onStatusUpdate?: (result: ForecastResult) => void` where `ForecastResult` is imported from `frontend/src/types/forecast.ts` (after BUG-011 is resolved).
- **Fix**: Replace `any` with the concrete `ForecastResult` type.

---

### [BUG-013] `BatchForecastResults` `selectedEntityId` not updated when new results arrive during polling
- **Severity**: Medium
- **Location**: `frontend/src/components/forecast/BatchForecastResults.tsx`, lines 73-75
- **Found in**: Yoki
- **Description**: `useState<string>(completedResults[0]?.entity_id || "")` captures only the initial render value. If `completedResults` is empty on mount (no entities finished yet when the component first renders during live polling), `selectedEntityId` stays empty forever. The dropdown populates with options as polling updates arrive but nothing is auto-selected and no chart appears.
- **Expected**: A `useEffect` should auto-select the first completed result whenever `selectedEntityId` is empty and new results arrive.
- **Fix**: `useEffect(() => { if (!selectedEntityId && completedResults.length > 0) { setSelectedEntityId(completedResults[0].entity_id); } }, [completedResults, selectedEntityId]);`

---

### [BUG-014] `_run_batch_background` has no top-level exception handler -- status stays `running` on crash
- **Severity**: High
- **Location**: `backend/app/services/forecast_service.py`, `_run_batch_background` method (lines 291-345)
- **Found in**: Nabil
- **Description**: If an unhandled exception propagates out of `_run_batch_background` (e.g. preprocessing service raises, Redis write fails), the asyncio Task fails internally but Redis retains the last-written `status: running`. The frontend polls indefinitely until TTL expiry with no indication the job crashed.
- **Expected**: Wrap the entire method body in try/except and write a FAILED batch status to Redis in the except block.
- **Fix**: Add top-level `try/except Exception as e` in `_run_batch_background`. In the except block, log the error and call `await self._store_batch_status(batch_id, failed_status)` with `status=ForecastStatus.FAILED`.

---

### [BUG-015] `MethodSettings = Record<string, any>` -- violates no-any rule
- **Severity**: Low
- **Location**: `frontend/src/app/[tenant]/forecast/page.tsx`, line 38
- **Found in**: Yoki
- **Description**: `type MethodSettings = Record<string, any>` propagates `any` through `forecastConfig.methodSettings` and into all API payload construction, bypassing TypeScript safety on the most variable part of the forecast request body.
- **Expected**: Use `Record<string, unknown>` at minimum, or a discriminated union for each method settings type.
- **Fix**: `type MethodSettings = Record<string, unknown>`

---

## Resolved Bugs

*(none yet)*

---

## Severity Reference

| Level | Meaning |
|-------|---------|
| Critical | Data loss, system crash, security breach, or core feature completely broken |
| High | Feature partially broken, data corruption possible, or serious UX failure |
| Medium | Edge case violation, code quality or duplication issue affecting maintainability |
| Low | Minor code standard violation, cosmetic or stylistic issue |

### [BUG-016] `DataPreview` refresh button bypasses `enabled` guard when `resource` is null
- **Severity**: Medium
- **Location**: `frontend/src/components/connectors/DataPreview.tsx`, lines 146-157
- **Found in**: Yoki
- **Description**: The fix in this review correctly adds `&& !!resource` to the `enabled` flag so the automatic query does not fire when no resource is selected. However, the Refresh button at line 150 calls `refetch()` unconditionally. In TanStack Query v5, `refetch()` bypasses the `enabled: false` guard and fires the underlying `queryFn`. When `resource` is null this sends `POST /fetch` with `table: undefined`, which will either error out or return unexpected data from the backend.
- **Expected**: The Refresh button should be disabled (or hidden) whenever `resource` is null, matching the same condition used on the `enabled` flag.
- **Fix**: Add `disabled={isFetching || !resource}` to the Refresh Button props (line 151). Optionally hide the entire controls row (`Select` + `Button`) behind a `resource &&` guard.

---

### [BUG-017] `TOP N` / `LIMIT N` in GROUP BY entity extraction does not prevent full table scan
- **Severity**: Low
- **Location**: `backend/app/api/v1/endpoints/connector_wizard.py`, lines 748-768
- **Found in**: Nabil / Omar
- **Description**: The `TOP 1000` (SQL Server) and `LIMIT 1000` (others) clauses are applied to the GROUP BY result set, not to the rows read from the table. The database engine must still scan the entire table and compute all aggregations before the limit is applied. On a table with hundreds of millions of rows the timeout risk is not eliminated -- only the result set returned to the application is capped. The fix is syntactically and logically correct for its stated secondary purpose (capping the returned entity list to 1000), but the timeout problem on very large tables remains unaddressed.
- **Expected**: Document the limitation clearly in a code comment. A true timeout-safe approach would require a subquery with a row-level limit before grouping (e.g. `SELECT entity_id, COUNT(*) FROM (SELECT TOP 1000000 entity_id FROM table) sub GROUP BY entity_id`), though this changes semantics. Alternatively, enforce a connection-level query timeout and surface it as a user-friendly error.
- **Fix**: Add a comment to the SQL block explaining that `TOP N` / `LIMIT N` caps the entity list returned to the caller, not the rows scanned. Escalate to Reem to decide whether a connection timeout or subquery approach is required for very large tenants.

---

---

### [BUG-018] Chained .bfill().ffill() inside groupby().transform() raises on duplicate-index groups
- **Severity**: High
- **Location**: `backend/app/services/preprocessing_service.py`, lines 393-395 (LINEAR_INTERPOLATE) and lines 406-408 (SPLINE_INTERPOLATE)
- **Found in**: Nabil
- **Description**: g.interpolate().bfill().ffill() inside a transform() lambda returns a Series carrying the group index. When the sort at line 339 produces duplicate timestamp values for the same entity (two rows on the same date), pandas raises ValueError: cannot reindex from a duplicate axis when transform tries to re-align the returned Series. This crashes missing-values handling for any dataset with duplicate timestamps per entity.
- **Expected**: Interpolation completes even when duplicate timestamps exist within an entity group.
- **Fix**: Append .values to every interpolation chain inside the lambdas so transform receives a numpy array and skips index alignment: g.interpolate(method="linear").bfill().ffill().values. Apply the same fix to both return paths in _spline_or_fallback.

---

### [BUG-019] missing_before over-counts nulls for numeric-only methods, inflating rows_affected
- **Severity**: Medium
- **Location**: `backend/app/services/preprocessing_service.py`, lines 326-328
- **Found in**: Nabil
- **Description**: missing_before sums nulls across all user-selected columns. FILL_MEAN and FILL_MEDIAN only process numeric columns (guarded by is_numeric_dtype). When the user selects a mixed set of numeric and string columns, null counts from non-numeric columns are included in missing_before but never filled. rows_affected = missing_before - missing_after is therefore overstated and the frontend toast displays an incorrect "X missing values filled" count.
- **Expected**: rows_affected reflects only the nulls actually filled by the chosen method.
- **Fix**: For FILL_MEAN and FILL_MEDIAN, scope both missing_before and missing_after to the numeric-only subset: numeric_cols = [c for c in columns if pd.api.types.is_numeric_dtype(df[c])], then sum nulls over numeric_cols only.

---

### [BUG-020] No warning when date column is absent and order-dependent fill is applied
- **Severity**: Medium
- **Location**: `backend/app/services/preprocessing_service.py`, lines 337-339
- **Found in**: Nabil
- **Description**: When _detect_date_column returns None, the sort is silently skipped and ffill/bfill/interpolation runs on whatever row order exists in Redis. The user receives no indication that fill correctness depends on row order or that chronological ordering could not be verified. Two otherwise identical datasets can produce different fill results depending on their Redis-cached row order.
- **Expected**: Users are warned when order-dependent methods are applied without a verified chronological sort.
- **Fix**: When date_col is None and request.method is in order_dependent, append to the response message: " Warning: no date column detected -- fill applied in current row order, which may not be chronological."

---

### [BUG-021] _detect_date_column keyword heuristic matches categorical columns, causing sort by wrong column
- **Severity**: Medium
- **Location**: `backend/app/services/preprocessing_service.py`, lines 893-909; called at line 338
- **Found in**: Nabil
- **Description**: _detect_date_column returns the first column whose name contains any of ["date", "time", "timestamp", "period", "day", "month", "year"]. A column named product_year (categorical int) or reporting_period_name (string) matches this heuristic. The date-sort at line 339 then sorts by a categorical column instead of a true timestamp. For ffill/bfill/interpolation this produces incorrect fill ordering. The bug is pre-existing but the new date-sort logic in handle_missing_values amplifies it from a cosmetic issue to a data-corrupting one.
- **Expected**: Only genuine datetime columns are used as sort keys.
- **Fix**: Escalate to Nabil to tighten _detect_date_column. A column should only qualify if its pandas dtype is already datetime64, OR its name matches a keyword AND pd.to_datetime(df[col], errors="coerce").notna().mean() > 0.8. The current OR logic (keyword match alone is sufficient) must be replaced with AND.

---

### [BUG-022] DROP toast re-computes rows_affected client-side instead of using the response value
- **Severity**: Low
- **Location**: `frontend/src/components/preprocessing/MissingValuesHandler.tsx`, line 158
- **Found in**: Yoki
- **Description**: The DROP branch shows result.rows_before - result.rows_after when the backend already returns this exact value as result.rows_affected. If the backend formula changes, the frontend will silently display a stale calculation. The fill-methods branch at line 160 correctly uses result.rows_affected directly.
- **Expected**: Both toast branches use result.rows_affected.
- **Fix**: Change line 158 from (result.rows_before - result.rows_after) to result.rows_affected.

---

### [BUG-023] total_rows declared in frontend type but absent from API response -- causes NaN percentage and undefined display
- **Severity**: High
- **Location**: `frontend/src/components/preprocessing/MissingValuesHandler.tsx`, lines 64-68, 172-174, 206; `backend/app/services/preprocessing_service.py`, lines 296-304
- **Found in**: Yoki / Nabil
- **Description**: The component state type declares total_rows: number and uses it at line 172 (analysis.total_rows * analysis.columns.length) and line 206 (display). The backend analyze_missing_values method returns a dict with keys columns, total_missing, total_cells, overall_percentage -- there is no total_rows key. At runtime analysis.total_rows is undefined, the Total Rows stat box renders the text "undefined", and totalMissingPercentage at line 172 evaluates to NaN, breaking the Progress bar for the overall missing percentage summary.
- **Expected**: The displayed row count is a valid integer and the overall missing percentage is a valid number.
- **Fix (Option A -- preferred)**: Add "total_rows": total_rows to the dict returned by analyze_missing_values (service line 299) and add total_rows: int to the MissingValuesResponse Pydantic schema. Option B: Remove total_rows from the frontend useState type, change line 172 to analysis.overall_percentage, and derive the displayed row count as Math.round(analysis.total_cells / Math.max(analysis.columns.length, 1)).

---

### [BUG-024] dtype field declared in frontend ColumnMissingInfo but never returned by backend -- renders empty Badge
- **Severity**: Medium
- **Location**: `frontend/src/components/preprocessing/MissingValuesHandler.tsx`, line 36 (interface), line 263 (usage); `backend/app/schemas/preprocessing.py`, lines 151-156
- **Found in**: Yoki / Nabil
- **Description**: The ColumnMissingInfo TypeScript interface declares dtype: string. The MissingValuesAnalysis Pydantic schema and the analyze_missing_values service method do not include a dtype field. At runtime col.dtype is undefined and the Badge element at line 263 renders empty, providing no visual cue about column data type -- information the user needs to select an appropriate fill method (e.g. mean/median are invalid for string columns).
- **Expected**: Column dtype (e.g. float64, object, int64) is displayed correctly in the column selection list.
- **Fix**: In the analyze_missing_values service loop, add "dtype": str(df[col].dtype) to each column entry. Add dtype: str to the MissingValuesAnalysis Pydantic model. This is a non-breaking additive change that does not affect existing callers.
