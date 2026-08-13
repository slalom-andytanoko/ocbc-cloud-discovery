---
title: CS-004 — JDBC/Oracle Connector Implementation Spec
category: reference
tags: [aws, ocbc, data-acquisition, worker, connector, jdbc, oracle, implementation, source-document]
relationships:
  - target: "[[reference/cloud-sync-user-stories]]"
    type: derived_from
  - target: "[[reference/data-acquisition-cloud-sync-detailed-design]]"
    type: derived_from
  - target: "[[reference/delivery-tranches-roadmap]]"
    type: related_to
  - target: "[[questions]]"
    type: related_to
provenance:
  extracted: 0.0
  inferred: 1.0
  ambiguous: 0.0
base_confidence: 0.85
lifecycle: draft
created: 2026-08-15
updated: 2026-08-15
---

# CS-004 — JDBC/Oracle Connector Implementation Spec

Implementation specification for **CS-004: Acquire from a relational source** — the JDBC/Oracle
`SourceConnector` for the `worker-service` in `ocbc-cloud-sync`. This is a Tranche 3 deliverable
(moved from T4 — confirmed implemented). CS-008 (Parquet landing) depends on this connector.

## Story acceptance criteria (from [[reference/cloud-sync-user-stories]])

**CS-004 — Acquire from a relational source**

> Given a pipeline whose `access_type` is `RELATIONAL` and whose source registry entry names an
> Oracle data source, when the Worker claims an `EXTRACT` task for that pipeline, then it executes
> the configured SQL query against the Oracle source via JDBC, streams the result set in bounded
> memory (CS-019), writes the output to the staging zone under `raw/{pipeline_id}/{batch_date}/`,
> produces a `_manifest.json` recording file count, total bytes, and per-file checksums, and
> returns an `EXTRACT` task result of `{manifest_uri, file_count, total_bytes}`.

**Exception paths:**

- Connection failure / timeout → `TRANSIENT` error; retried per CS-016 (A4 config table)
- Permission denied (Oracle `ORA-01031` or JDBC `AccessDeniedException`) → `PERMANENT` /
  `SOURCE_DB_ACCESS_DENIED`; run fails immediately, no retry
- Query returns zero rows → treated as a valid empty extract (file_count=0); run proceeds
- Query error (bad SQL, ORA-00942 table not found, etc.) → `PERMANENT` / `SOURCE_QUERY_ERROR`
- Result set exceeds the per-pipeline `max_extract_bytes` ceiling (CS-019) → `PERMANENT` /
  `SOURCE_FILE_TOO_LARGE`; run fails naming the pipeline

---

## Design constraints (from [[reference/data-acquisition-cloud-sync-detailed-design]])

- **DD-08 — shared logic as libraries.** The connector is a `dal-connectors` library class, not a
  separate service. It is instantiated in-process by the Worker's `WorkerTaskExecutor`.
- **DD-13 — per-source connection ceiling.** A bounded `HikariCP` pool per source
  (`max_connections` from the source registry, env default when absent) covers both `EXTRACT` and
  `CHECK_READINESS` tasks for the same source. The pool is keyed by `source_id`.
- **CS-019 — bounded-memory streaming.** The result set must be streamed row-by-row via JDBC
  `setFetchSize` (Oracle thin driver: `stmt.setFetchSize(1000)` disables prefetch). The connector
  must never materialise the full result set in heap.
- **CS-009 — pass-through byte integrity.** The manifest checksum (SHA-256) is computed over the
  bytes written to S3, not over the JDBC byte stream, so the checksum covers the exact object
  content DataSync will transfer.
- **Output format.** Relational extracts land as **Parquet** (CS-008). The Parquet writer is a
  separate concern (see A8 in [[questions]]); the connector's contract is to produce a
  `RecordBatch` / `RowIterator` that the Parquet writer consumes. For the initial CS-004 delivery,
  the connector may write a **CSV** intermediate if the Parquet writer (Q-16 mapping sign-off) is
  not yet finalised — the manifest records the format, and the Parquet conversion step is added
  once Q-16 is closed.

---

## Implementation plan

### 1. `OracleSourceConnector` — `dal-connectors` library

**Package:** `com.ocbc.dal.connectors.relational`

**Class:** `OracleSourceConnector implements SourceConnector`

```
SourceConnector interface (existing):
  ConnectorResult extract(ExtractContext ctx) throws ConnectorException
```

**`ExtractContext`** fields needed (add if not present):
- `sourceId` — for pool keying
- `jdbcUrl`, `username` — resolved from CyberArk/Conjur at call time (CS-002 stand-in: env var
  for this tranche, same pattern as the file connector's path resolution)
- `extractQuery` — the SQL to execute (from `source_registry.extract_query`)
- `batchDate` — bound as `:batch_date` / `?` parameter
- `maxExtractBytes` — CS-019 ceiling (from pipeline config, env default)
- `stagingPrefix` — `raw/{pipeline_id}/{batch_date}/` on the staging S3 bucket
- `fetchSize` — default 1000, per-pipeline overridable

**Core logic:**

```
1. Acquire a connection from the per-source HikariCP pool (keyed by sourceId).
2. Prepare the extract query; bind :batch_date.
3. Set stmt.setFetchSize(fetchSize) — disables Oracle prefetch, enables row-by-row streaming.
4. Execute; open ResultSet.
5. Open a streaming Parquet/CSV writer against an S3MultipartUpload for the output object key:
     raw/{pipeline_id}/{batch_date}/{source_system_id}_extract.parquet  (or .csv interim)
6. For each row:
   a. Write the row to the Parquet/CSV writer.
   b. Accumulate bytesWritten; if bytesWritten > maxExtractBytes → abort upload,
      throw ConnectorException(SOURCE_FILE_TOO_LARGE, PERMANENT).
7. Close writer → finalise S3 multipart upload → record ETag + size.
8. Compute SHA-256 over the uploaded bytes (via S3 HeadObject or digest during write).
9. Write _manifest.json to the same prefix:
     { "pipeline_id", "batch_date", "file_count": 1, "total_bytes",
       "files": [{ "key", "size_bytes", "sha256" }],
       "format": "PARQUET" | "CSV",
       "compression": false }
10. Return ConnectorResult{ manifestUri, fileCount=1, totalBytes }.
```

**Error mapping** (consistent with the existing `AccessDeniedException` pattern from CS-006):

| JDBC / Oracle exception | `error_code` | `error_class` |
|---|---|---|
| `SQLTimeoutException`, `SocketTimeoutException`, connection reset | `SOURCE_DB_TIMEOUT` | `TRANSIENT` |
| `SQLException` with `ORA-01031` / `AccessDeniedException` | `SOURCE_DB_ACCESS_DENIED` | `PERMANENT` |
| `SQLException` with `ORA-00942`, `ORA-00904` (bad SQL/table) | `SOURCE_QUERY_ERROR` | `PERMANENT` |
| Bytes ceiling exceeded | `SOURCE_FILE_TOO_LARGE` | `PERMANENT` |
| Any other `SQLException` | `SOURCE_DB_ERROR` | `TRANSIENT` (default — retry) |

### 2. HikariCP pool factory — `dal-connectors`

**Class:** `RelationalConnectionPoolFactory`

- Keyed by `sourceId`; pools are created lazily and cached in a `ConcurrentHashMap`.
- Pool config: `maximumPoolSize` = `source_registry.max_connections` (env default: 5).
- `connectionTimeout` = 30 s; `idleTimeout` = 10 min; `maxLifetime` = 30 min.
- Oracle thin driver: `jdbc:oracle:thin:@//{host}:{port}/{service}`.
- Credentials resolved from the stand-in env vars `DAL_ORACLE_{SOURCE_ID}_USERNAME` /
  `DAL_ORACLE_{SOURCE_ID}_PASSWORD` (same pattern as the file connector; replaced by CyberArk
  Conjur in T6a, CS-002).

### 3. Worker wiring — `worker-service`

**`WorkerTaskExecutor`** — add a branch for `access_type = RELATIONAL`:

```java
case RELATIONAL -> oracleSourceConnector.extract(buildOracleContext(task, pipeline));
```

**`WorkerClaimLoop`** — no change needed; task type routing already dispatches by `access_type`
(same pattern as the file/S3 connector routing added for CS-006/007).

**`application.yml`** additions:

```yaml
worker:
  source:
    oracle:
      fetch-size: 1000          # default; per-pipeline override via source_registry
      max-extract-bytes: 5368709120  # 5 GiB default; per-pipeline override
      connection-timeout-ms: 30000
```

### 4. Schema additions

No new tables. Add columns to `source_registry` (or the pipeline config table — consistent with
the A3/A4 layered config model):

```sql
-- source_registry additions
extract_query          TEXT,          -- parameterised SQL; :batch_date bound at runtime
max_connections        INT,           -- per-source pool ceiling (CS-047 / DD-13)
fetch_size             INT,           -- JDBC fetch size override (default 1000)

-- pipeline_config additions (per-pipeline overrides)
max_extract_bytes      BIGINT,        -- CS-019 ceiling; env default 5 GiB
```

### 5. Tests

**Unit tests** (`OracleSourceConnectorTest`):

| Test | CS-xxx | Assertion |
|---|---|---|
| Happy path — rows extracted, manifest written, result returned | CS-004, CS-009 | `ConnectorResult.fileCount == 1`, manifest SHA-256 matches |
| Zero-row result — empty extract, manifest written | CS-004 | `fileCount == 0`, no error |
| Bytes ceiling exceeded mid-stream | CS-019 | `SOURCE_FILE_TOO_LARGE` / `PERMANENT` thrown |
| `ORA-01031` permission denied | CS-004 | `SOURCE_DB_ACCESS_DENIED` / `PERMANENT` |
| `ORA-00942` bad table | CS-004 | `SOURCE_QUERY_ERROR` / `PERMANENT` |
| Connection timeout | CS-004, CS-016 | `SOURCE_DB_TIMEOUT` / `TRANSIENT` |
| `setFetchSize` called with configured value | CS-019 | verify no full-RS materialisation |

**Integration test** (`OracleExtractFlowIT` — Testcontainers):

- Spin up `gvenzl/oracle-xe` container (Oracle XE, free tier, ~2 GB image).
- Seed a `BATCH_CONTROL` table + a `SOURCE_DATA` table with 3 rows.
- Run a full `EXTRACT` task end-to-end against LocalStack S3.
- Assert: object exists under `raw/`, manifest present, `file_count=1`, SHA-256 matches.
- Assert: a second run with the same `pipeline_id + batch_date` is idempotent (CS-015 — dedup
  guard in the Orchestrator, not the connector, but the IT should confirm no duplicate object).

**`@DisplayName` convention** (steering §10): every `@Test` must carry `@DisplayName` with the
`CS-004` / `CS-019` / `DD-13` IDs it covers.

---

## Dependency on CS-008 (Parquet landing)

CS-008 requires the approved Oracle→Parquet column-type mapping (Q-16 sign-off, see A8 in
[[questions]]). Until Q-16 is closed:

- The connector writes **CSV** (UTF-8, comma-separated, header row with column names).
- The manifest records `"format": "CSV"`.
- The Parquet writer is a separate `ParquetConverter` class that wraps the connector output; it
  is wired in once Q-16 is signed off.
- This is an **accepted deviation** (same class as DD-B3/DD-B4 in the steering register) — record
  it in `steering/design-decisions-and-guardrails.md` as `DD-B-CS004-CSV-INTERIM`.

---

## DoD checklist (per [[reference/cloud-sync-user-stories]] §3)

- [ ] All acceptance criteria above have a named test assertion (`@DisplayName` / CS-004)
- [ ] `OracleExtractFlowIT` passes against Testcontainers Oracle XE + LocalStack
- [ ] JaCoCo branch coverage ≥ 85% (reactor-wide, not just the new class)
- [ ] Spotless / Checkstyle / PMD green
- [ ] No `CRITICAL`/`HIGH` findings in the CI security scan (finding #12 — confirm authority)
- [ ] `steering/design-decisions-and-guardrails.md` updated with `DD-B-CS004-CSV-INTERIM`
- [ ] `README.md` known-limitations section updated (CSV interim, Q-16 dependency)
- [ ] CS-008 dependency documented in the PR description

---

## Related

- [[reference/cloud-sync-user-stories]] — CS-004, CS-008, CS-019
- [[reference/data-acquisition-cloud-sync-detailed-design]] — DD-08, DD-13, §5.1 task result contract
- [[reference/delivery-tranches-roadmap]] — Tranche 3
- [[questions]] — A8 (Parquet landing inputs), A4 (retry config)
- [[deliverables/findings]] — #15 (CS-004 deferred note), #17 (this implementation)
