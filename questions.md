---
title: Questions to Complete the Project
category: meta
tags: [questions, tracking, delivery, data-acquisition]
updated: 2026-08-11
cssclass: wide-page
---

# Questions to Complete the Project

Consolidated list of every open question that must be answered to **complete delivery of the
OCBC Data Acquisition (Cloud Sync) platform** — from the code implementation (`ocbc-cloud-sync`,
Tranches 1 & 2 delivered, Tranche 3+ pending) through to the wider engagement decisions the
platform depends on.

Compiled from: [[open-questions]], [[synthesis/data-acquisition-open-decisions]],
[[reference/cloud-sync-user-stories]] (Q-01–Q-12), [[deliverables/findings]], and the
`ocbc-cloud-sync` steering `design-decisions-and-guardrails` register (DD-B accepted deviations
that still need a design-owner ruling). Resolved items are listed once at the bottom for
traceability. Each question notes **who** should answer it and **what it blocks**.

> This is the forward-looking "what's left to decide/answer" view. [[open-questions]] remains the
> historical session-raised register; this page pulls the still-open ones together with the
> implementation- and delivery-level questions that aren't in that register.

---

## Reference codes used on this page

Many rows cite a short code instead of spelling the source out in full. Here is what each family
means and where it lives, so a code can be read without chasing the link:

| Code | What it is | Where it comes from |
|------|------------|---------------------|
| **CS-nnn** | A Cloud Sync **user story** — a numbered requirement with acceptance criteria (e.g. CS-021 readiness, CS-041 replay) | [[reference/cloud-sync-user-stories]] |
| **CR-nn** | A **Change Request** against platform design v1.1, raised during requirements review (§8) | [[reference/cloud-sync-user-stories]] |
| **Q-nn** | An open question in the **User Stories** doc's *own* register (§9, Q-01–Q-12) | [[reference/cloud-sync-user-stories]] |
| **OQ-nn** | An open question in the **Platform on AWS** design docs (v1.1 / v1.3, §16) | [[reference/data-acquisition-platform-v1.3]] |
| **DD-Ax / DD-Bx** | An entry in the `ocbc-cloud-sync` code repo's steering register — **DD-A** = standing rules the code must keep, **DD-B** = accepted deviations from spec | `ocbc-cloud-sync/steering/design-decisions-and-guardrails.md` |
| **BL-nnn** | A **backlog** requirement, deliberately deferred out of the current build | *OCBC Data Acquisition - Backlog Requirements* |
| **RSK-nn** | A **delivery risk** in the platform doc's risk register (Appendix E) | [[reference/data-acquisition-platform-v1.3]] |
| **D-nn / A-nn** | A numbered design **D**ecision / **A**ssumption in the platform design (e.g. D18 encryption, D27 CMK, A17 single non-prod) | platform v1.x |
| **findings #n** | A row in the engagement's **findings register** | [[deliverables/findings]] |
| **§n** | A section number *within* the source document named alongside it | (as cited) |

---

## A. Questions blocking code completion (implementation design-owner rulings)

These are decisions the `ocbc-cloud-sync` delivery team / DAL design owner must make before the
next tranches can be built without rework. Sources in the code repo's steering register and
[[deliverables/findings]] #16. The **Spec coverage** column records whether the Cloud Sync user
stories already settle the item — the recurring pattern is that the spec fixes the *behaviour*, so
what's left for most rows is a concrete value, a sign-off, or the build itself, **not** a design
ruling.

> **Application ownership & layered config (2026-08-11):** `application` (the owning tenant,
> aligning with the `dacq-<env>-<app>-<tier>` buckets and the `target_tier` classify-and-promote
> resolves) is an attribute of the **pipeline** (`pipeline_config.application`) and the **source**
> (`source_registry.application`) — it is **not** independently repeated on each config table. Retry
> (A4) uses a **layered** model: a per-pipeline override → an application-level default (a table
> keyed by `application`) → the environment default. Readiness (A3, per-pipeline) and retention
> (A6, per-source) keep their natural grain and inherit the parent's application via join.

| # | Question | Owner | Blocks | Source | Spec coverage |
|---|----------|-------|--------|--------|---------------|
| A1 | ✅ **RESOLVED (2026-08-11)** — **SLA breach is a distinct terminal status.** Implemented per Detailed Design §6.1: `Run.breachSla()` transitions the run into the terminal `SLA_BREACH` status (reachable from any non-terminal state) with an `SLA_BREACHED` audit event; the earlier boolean flag (`Run.slaBreached`) was removed. This also closed the never-terminating never-ready run. | — | — | steering DD-B1 (Resolved) | ✅ CS-027 — terminal `SLA_BREACH` + alert |
| A2 | **Production auth model.** Confirm the API-key stand-in (`ApiKeyAuthFilter`) is replaced by Spring Cloud Gateway + Entra ID / mTLS at the gateway tier, and how operator identity is verified for `resume`/`replay`/`cancel` (today `actingIdentity` is caller-supplied, unverified). | Security / platform team | Tranche 6a (gateway), production sign-off | DD-B5, CS-037/038, §3.2/§13.4 | ⚠️ Target model **is** in CS-037/038 (token issuer/audience/expiry/entitlement, per-caller confinement, network-level internal trust); the gap is that the **code still runs the stand-in** — a real implementation decision, not just a value |
| A3 | ✅ **ANSWERED (2026-08-11)** — **Readiness = a configured `COUNT(*)` poll (CS-021).** Decided by the DAL owner: the **poll window and poll interval live in the pipeline configuration table** (per-pipeline, env-default fallback), and the readiness check is a **parameterised `SELECT COUNT(*)`** against the source's control table, filtered by a **bound date** (`:batch_date`) and a **status filter** (`Status IN ('COMPLETE','DONE', …)`) — the source is **ready when the count ≥ the expected value** (default `≥ 1`). CS-021's outcomes stand: poll-window expiry → `run.fail()` with `READINESS_TIMEOUT` + alert; a readiness-*query* error retries per CS-016 within the window. Config schema + example SQL in the A3 note below. | — | — | CS-021 (config table + COUNT query) | ✅ Answered — CS-021 mechanism + config-table placement + `COUNT(*)` query decided; per-pipeline values set at onboarding |
| A4 | ✅ **ANSWERED (2026-08-11)** — **Retry & backoff = config-table driven, no jitter (CS-016).** Decided by the DAL owner: the retry schedule lives in the **pipeline configuration table** (per-pipeline, env-default fallback) — base delay, multiplier, cap, max attempts — and backoff is **deterministic exponential (no jitter)**: `delay = min(cap, base · 2^attempt)`. CS-016's mechanism stands: transient → retry to the configured limit + checkpoint resume; permanent → immediate fail; exhaustion → fail + alert (CS-043) + quarantine (CS-042); on-demand not retried past the response limit. The `TRANSIENT`/`PERMANENT` map (A4 note below) seeds the config table as defaults. | — | — | CS-016 (config table, no jitter) | ✅ Answered — CS-016 mechanism + config-table schedule + no-jitter backoff decided; concrete values seed the table |
| A5 | ✅ **RESOLVED (2026-08-11) as a design ruling** — **Business-date resolution is fully specified by Epic G, so no design-owner ruling is needed.** CS-060 enumerates the special-value token set (`CURRENT_DATE`, `PREVIOUS_MONTH_END_DATE`, …), CS-061 defines the system-wide anchor date + scheduled Control-M roll-over (incl. its ownership), CS-062 defines per-country calendars with configurable weekend patterns; all failure modes are fail-closed. The only remainders are **not open questions**: loading each country's holiday **calendar data** (an operating-model / ownership follow-on) and building the resolver library in the **final Tranche 7** (split out of Tranche 3 on 2026-08-12). The `batch_date_resolved` field is already present in the API (literal passthrough, DD-B4 partially resolved). | — | — | v1.3 Epic G, CS-060/061/062 | ✅ Design settled by Epic G; only calendar **data** + Tranche 7 build remain (neither is a design ruling) |
| A6 | **Housekeeping / retention values (Q-03).** Retention for `run` / `run_task` / `run_event` / `push_run` and each zone, satisfying "audit retention ≥ zone retention + max re-run/replay latency" so the CS-015 dedup guard is never archived early. **Storage decided (2026-08-11): retention values live in the configuration table** (per-source / per-zone, consistent with CS-059). **Recommended values proposed:** audit **90 d**, dedup **30 d**, staging & transfer-ready zones **7 d** each, max replay latency **30 d**, regulatory archive **~7 yr** — pending **compliance sign-off** (Q-03). *(Full table in the **A6 note** below.)* | Data platform + **compliance** (sign-off) | Archival jobs, dedup-window guarantee | Detailed Design §7.2, CS-059 | ⚠️ Storage decided (config table, CS-059); **values proposed** (90/30/7/7/30 d + ~7 yr archive), pending compliance sign-off (Q-03) |
| A7 | ✅ **RESOLVED (2026-08-11)** — **S3 source connector, ETag check, and multipart abort implemented (CS-007).** `S3SourceConnector` (config-selected via `worker.source.type=S3`) reads with a `HeadObject` size guard then a `GetObject` pinned with `ifMatch(eTag)` (412 ⇒ object changed ⇒ fail); `S3Uploader` writes single-part `PutObject` below a threshold and multipart with `AbortMultipartUpload` above it. DD-B2 resolved. | — | — | DD-B2 (Resolved) | ✅ CS-007 — ETag pin + multipart abort |
| A8 | **Parquet landing (CS-008).** Confirm CS-008 waits on CS-004 (JDBC/Oracle connector, Tranche 4) and the approved type mapping (§9.6.1). *(Inputs needed detailed in the **A8 note** below.)* | DAL design owner | Tranche 4 | DD-B3, CS-008, findings #15 | ⚠️ Contract settled by CS-008; only the §9.6.1 mapping **sign-off (Q-16)** + the **CS-004** dependency (Tranche 4) open |
| A9 | **Definition-of-Done authority (finding #12).** Is the 16-item `dod.md` or the 17-item variant (adds "no Critical/High CVEs in a CI security scan") the canonical release gate? | Delivery lead | Release sign-off | findings #12 | n/a — out of scope for the user stories (internal DoD governance, not a spec matter) |

**Bottom line.** The only Section A item the user stories leave open *on purpose* is **A6** (Q-03) —
and there the storage is decided (config table, per-source / per-zone) and the **values are now
proposed** (audit 90 d, dedup 30 d, zones 7 d, replay 30 d, regulatory archive ~7 yr), leaving only
compliance **sign-off**. **A8** is behaviour-settled by CS-008 — it needs the Q-16 sign-off and the
CS-004 dependency, not a design ruling. **A3**, **A4**, and **A5** are now closed as design rulings —
A3 and A4 by the DAL owner (config-table driven: a `COUNT(*)` readiness poll and a no-jitter retry
schedule) and A5 by Epic G. **A2** is the only item that is both spec-defined *and* a live
implementation decision (replace the stand-in). **A1** and **A7** are implemented. **A9** is not a
spec matter.

### A3 — answered: readiness = a configured `COUNT(*)` poll (CS-021)

**Answer (2026-08-11, DAL design owner).** Readiness is a **configured, parameterised `SELECT COUNT(*)`
poll**. The poll **window and interval live in the pipeline configuration table** (the source
registry), not in code — per-pipeline, with an env-default fallback:

| Config column | Meaning | Default |
|---|---|---|
| `readiness_query` | parameterised `SELECT COUNT(*)` against the source's control / batch table | *(per source)* |
| `readiness_expected_count` | the count that means "ready" | `≥ 1` |
| `readiness_poll_interval_seconds` | polling cadence (bounds shared source-DB load, CS-047) | 30 (prod) / 5 (demo) |
| `readiness_poll_window_minutes` | give-up window — **must be < the pipeline SLA** | 60 |

The poll query is a `COUNT(*)` with a **bound date** and a **status filter** — the source is ready
when the count reaches the expected value:

```sql
SELECT COUNT(*)
FROM   BATCH_CONTROL                     -- the source's control / batch table
WHERE  Business_Date = :batch_date       -- bound from the run context
  AND  Status IN ('COMPLETE', 'DONE');   -- the source's ready / terminal status set
-- ready when COUNT(*) >= readiness_expected_count (default >= 1)
```

A `COUNT(*)` returns a single comparable value, so this fits CS-021's "any query that returns a
single comparable value" model — it just fixes the shape (count of rows in a ready state) instead of
reading a status string. **Outcomes are exactly CS-021's:** poll-window expiry → `run.fail()` with
`error_code = READINESS_TIMEOUT` + alert (CS-043), no auto-retry (operator replays, CS-041); a
readiness *query* error (connection / permission) is retried per CS-016 within the window (that
retry path depends on A4). The reasoning below (kept for context) explains why the readiness window
is separate from the SLA.

**Starting point.** Since SLA breach became a *terminal* `SLA_BREACH` status (A1), a never-ready run
**is already stopped** by the SLA backstop. So the original "polls forever" defect is closed. A
dedicated readiness window is therefore **not a correctness fix** — it is an observability / quality
improvement. Its value is: catch upstream non-delivery *earlier*, with the *right label*, routed to
the *right owner*, and stop wasting polls on a source we don't own.

**Recommendation.** Add a **dedicated readiness poll-window, separate from the SLA**, that on expiry
FAILs the run with a distinct `READINESS_TIMEOUT` error (reuse the terminal `FAILED` state + a
distinct `error_code`; leave `checkpoint = CHECK_READINESS` for diagnostics). Set the readiness
window **shorter than** the SLA deadline so the precise cause fires before the generic `SLA_BREACH`
backstop. Don't auto-retry a readiness timeout (replay once the source confirms delivery); do keep
retrying a readiness *query error* (connection/permission) within the window per CS-016.

**"Why not just set a tight SLA per pipeline?"** (The SLA *is* already per-pipeline —
`pipeline.getSlaDeadlineMinutes()` with an env default.) One timer still can't do the readiness job
cleanly, because the SLA bounds the **whole run** (`readiness-wait + extract + validate + compress +
transfer + decompress`), and readiness-wait vs processing-time are **independent, additive budgets**:

- *One number can't tighten one budget without squeezing the other.* Example — readiness normally ≤
  30 min, processing ≤ 60 min: to avoid false alarms the SLA must be ≥ 90 min, so a never-ready run
  isn't caught until 90 min (too late); set SLA = 35 min to catch it fast and a healthy run whose
  readiness legitimately took 30 min has only 5 min for 60 min of work → **guaranteed false breach**.
  The readiness window nests *inside* the SLA precisely to separate these.
- *Wrong knob, wrong owner.* The SLA is a **business** commitment (when must data land), owned by the
  consumer; the readiness window is an **operational** bound on an upstream dependency, owned by the
  platform/source team. Overloading the SLA to also do hang-detection **pollutes SLA-breach
  reporting** with upstream non-deliveries.
- *It still can't tell you why.* Two `SLA_BREACH`es can't distinguish "source never delivered" from
  "transfer was slow" without opening each run.

**When SLA-alone is a defensible MVP.** If a pipeline's processing time is small and predictable
relative to its readiness variability, tuning the per-pipeline SLA gets you most of the way with
**zero new code** — it stops the hang and alerts today. The dedicated readiness window earns its keep
once there are many pipelines, sources with genuinely slow/variable readiness, or an ops team that
needs to route "upstream didn't deliver" separately. CS-021's acceptance criteria *do* specify the
dedicated readiness-timeout as a named exception path, so building to the user-stories baseline
requires it eventually:

> **CS-021 (Exception paths), verbatim:** *"Given the configured poll window expires without the query
> ever returning the expected ready value, when it expires, then the run is marked failed with a
> **readiness-timeout error and an alert is raised**."*
>
> So the behaviour A3 asks about — **fail** (not merely alert) with a **distinct readiness-timeout
> cause**, **and** an alert — is already mandated by CS-021; the poll window and interval are held as
> **configuration** (the source registry holds a "poll window duration" and "poll interval"), and a
> readiness *query error* (≠ "not ready") is "retried per CS-016 within the poll window." What CS-021
> leaves open is only the **concrete default values**. The alert's *delivery route* is CS-043, which
> lists "a readiness window expires" among its alert conditions — so `alert (CS-043)` names the
> mechanism, it does not add a requirement.

**Config-table defaults** (decided 2026-08-11 — these live per-pipeline in the pipeline configuration
table, with an env-default fallback):

> **Polling ≠ retry (A3 vs A4).** A3 has three distinct behaviours: **polling** (re-run the readiness
> query every interval while the answer is "not ready" — expected *waiting*, not a failure, and this
> already exists in the code); **give-up** (poll-window expiry → FAIL, the substance of A3); and, only
> for the case where the readiness query itself *errors*, **retry** — which is A4's (CS-016) mechanism.
> So A3's polling/give-up are independent of A4; only the query-error-retry row below depends on A4.

| Parameter | Proposed default |
|---|---|
| readiness poll-window | **60 min** (per-pipeline overridable; env default) |
| readiness poll-interval | **30 s** in production (bounds shared source-DB load, CS-047); currently 5 s in the demo config. This is the *polling* cadence — a "not ready" result is expected waiting, **not** a retry |
| relationship to SLA | window **must be < the pipeline's SLA deadline** so `READINESS_TIMEOUT` fires before the `SLA_BREACH` backstop (default SLA 240 min ⇒ 60 < 240 ✓) |
| expiry outcome (give-up) | `run.fail()` with `error_code = READINESS_TIMEOUT` (PERMANENT); leave `checkpoint = CHECK_READINESS`; raise alert (CS-043); **no auto-retry** — operator replays once the source confirms delivery (CS-041) |
| readiness *query* error (≠ "not ready") | retry within the window per CS-016 — **depends on A4**; until A4's retry engine lands, a readiness-query *error* just fails the run like any other failure |
| measured from | run initiation |
| unconfigured | fail-closed to the env default — never poll unbounded |

### A4 — answered: config-table retry, no jitter (CS-016)

**Answer (2026-08-11, DAL design owner).** The retry schedule is **layered**: a per-pipeline
override → an **application-level default** (a table keyed by `application`) → the environment
default (resolution stops at the first present). `application` is the pipeline's own attribute
(`pipeline_config.application`), not repeated on the retry tables. Backoff is **deterministic
exponential with no jitter**. The values below are the seed defaults.

**Backoff** — exponential, **no jitter**, config-table driven: `delay = min(cap, base · 2^attempt)`:

| Config column | Meaning | Default |
|---|---|---|
| `retry_base_delay_seconds` | first backoff delay | 5 |
| `retry_multiplier` | growth factor per attempt | 2 |
| `retry_max_delay_seconds` | cap on any single delay | 300 (5 min) |
| `retry_max_attempts` | attempts before giving up (per task) | 5 |
| on exhaustion | `run.fail()` + alert (CS-043) + quarantine the batch (CS-042) | — |
| attempt tracking | `retry_count` column on `run_task`, recorded in the audit trail | — |

**Error classification** — the seed `TRANSIENT`/`PERMANENT` map for the config table; acts on the
`error_class` already captured in `result_payload`:

| Class | Codes / conditions | Behaviour |
|---|---|---|
| **TRANSIENT** (retry w/ backoff) | network / connection reset / refused; socket / query / read timeout; throttle / rate-limit (honour `Retry-After`); vault-unreachable credential resolution (CS-002); cloud / S3 5xx / 503 SlowDown / RequestTimeout; readiness-query connection error (≠ "not ready"); DB deadlock / lock-timeout; **connection dropped mid-read** (CS-004/006) | retry up to max attempts |
| **PERMANENT** (fail now) | config error / unknown pipeline; authorization / permission denied (403, AccessDenied, `SOURCE_FILE_ACCESS_DENIED`); `SOURCE_FILE_NOT_FOUND` (source hasn't delivered → replay, not retry); `SOURCE_FILE_TOO_LARGE` (CS-019); `SOURCE_OBJECT_CHANGED` / 412 (CS-007); unsupported type / no approved mapping (CS-003/008); format / size mismatch (CS-054) | fail immediately, no retry |
| **never-retried** | VALIDATE FAIL (CS-012/053) | terminal by design; re-acquire via replay (CS-041) |

**Mode 2 (on-demand):** not retried beyond the request's response-time limit (CS-016) — the caller
retries. **Key distinction:** a *connection dropped mid-read* is TRANSIENT (discard partial, re-read),
but a *file that isn't there* (`SOURCE_FILE_NOT_FOUND`) is PERMANENT — redelivery is a source action,
so the operator replays once readiness (CS-021/022) confirms the batch landed.

### A6 — retention defaults (Q-03) — **storage decided; values proposed, pending compliance sign-off**

> **Storage (decided 2026-08-11):** retention values live **in the configuration table**, per-source /
> per-zone (consistent with CS-059's "per-source retention period configured for each zone"), like the
> A3 readiness and A4 retry config. **Values (proposed below):** concrete recommended defaults — these
> are a **compliance** decision (Q-03), so they seed the config table pending compliance sign-off.
>
> Governing rule: **audit retention ≥ zone retention + max replay latency**, so the CS-015 dedup
> guard is never archived while a batch could still be replayed. The table below is the recommended
> operational **hot-store** seed; the long-term regulatory archive is separate (last row).

| Config column (per-source) | Store / window | Recommended value | Rationale |
|---|---|---|---|
| `audit_retention_days` | `run` / `run_task` / `run_event` / `push_run` (hot Postgres) | **90 days** | must exceed zone retention + replay window |
| `dedup_window_days` | deduplication guard (CS-015) | **30 days** | ≤ audit retention; ≥ longest hold (CS-028) + zone retention |
| `staging_zone_retention_days` | staging zone | **7 days** | investigate + resume window |
| `transfer_ready_zone_retention_days` | transfer-ready zone | **7 days** | investigate + replay window |
| `max_replay_latency_days` | max re-run / replay latency | **30 days** | operator can replay a corrected batch within this |
| `regulatory_archive_years` (cold storage, separate) | long-term audit archive | **7 years** *(compliance to confirm)* | banking record-keeping; archived out of the hot store to the data lake / cold storage |

Constraint check: audit 90 d ≥ zone 7 d + replay 30 d = 37 d ✅. Cleanup is **fail-safe to retain** —
no configured value ⇒ delete nothing (CS-045/CS-059).

**Still a genuine compliance input:** long-term **regulatory** archival of audit records (banks
commonly mandate multi-year, e.g. 7 years) is a *separate* decision — archive to the data lake /
cold storage out of the hot Postgres store. The 90-day figure above is the operational hot-store
default, **not** the regulatory record-keeping period.

### A8 — inputs needed for Parquet landing (CS-008)

CS-008 lands relational (JDBC/Oracle) extracts in S3 as **Parquet** using the approved column-type
mapping (v1.2 §9.6.1). It is a **data contract with the consuming AI/ML applications**, not an
implementation detail — which is why the exact mapping is the requirement.

**Why it is Tranche 4 (a dependency, not a decision blocker).** CS-008 cannot run until the
JDBC/Oracle source connector (**CS-004**) exists, which is scheduled for Tranche 4. So A8 is largely
a confirmation of that sequencing, plus the inputs below (DD-B3, findings #15).

| # | Input needed | Owner | Note |
|---|---|---|---|
| 1 | **Approved column-type mapping (§9.6.1)** — the core input | Consuming app teams (Q-16 sign-off) | Oracle NUMBER precision/scale → Parquet DECIMAL; DATE / TIMESTAMP / TZ logical types; CLOB / BLOB handling + max-value-size (CS-019); **lossless by default**; an unmapped type ⇒ run **fails naming the column** |
| 2 | Mapping ownership + versioning | DAL design owner + consumers | mapping version is recorded in the manifest; changes are versioned and approved |
| 3 | Target Parquet file size (splitting) | DAL design owner | an extract over the target size splits into ~target-sized files, each listed in the manifest; per-pipeline + env default |
| 4 | Compression codec | DAL design owner | Parquet-**internal** per-column-chunk codec set per pipeline (CS-010); no external compression wrapper |
| 5 | Confirm null/required + multi-table layout | DAL design owner | not-null source column ⇒ **required** Parquet field, others optional; a multi-table extract adds a `<table_name>/` level (CS-068) |

**Buildable now (without the inputs):** the Parquet writer + a versioned mapping-table engine,
target-size splitting, codec config, and the "unmapped type ⇒ fail" guard — all parameterised. What
you **cannot** do: exercise the real end-to-end path until CS-004 lands (Tranche 4), and finalise the
**mapping table**, which is a consuming-team contract (Q-16). A proposed default Oracle→Parquet
mapping + codec/file-size defaults can be added here on request.

---

## B. Requirements / specification questions still open (user-stories Q-01–Q-12)

The Cloud Sync User Stories §9 register. Answering these lets the acceptance criteria for the
un-built epics be finalised. Owner: **data platform team + relevant source/business owners**.

| # | Question | Blocks |
|---|----------|--------|
| B1 | **Payload / volume profiles per source** — expected file sizes, row counts, and run frequency for each source. Answers the platform doc's open question **OQ-01** (performance / scale volumes). | DataSync agent-pool + PostgreSQL sizing |
| B2 | **Default schema-drift action per classification tier** — when a source's schema changes, should the run WARN or FAIL, and does that depend on the data's classification level? Tracked as user-stories question **Q-20**, parked because the schema-change detector itself (**BL-005**, story CS-013) is deferred to the backlog. | Schema-drift validator (deferred) |
| B3 | **Zone retention windows** — how long staged / transfer-ready / audit data is kept (the same value question **A6** above needs). | Retention / archival design |
| B4 | **Replay semantics** — exact linked-run behaviour and audit expectations when an operator replays a batch (story CS-041). | Resume / replay hardening |
| B5 | **Push idempotency edge cases** — deduplication behaviour on the synchronous *push* path (interface Mode 2). | Sync Push Service (Tranche 5) |
| B6 | **Synchronous push size / duration limits** — the maximum payload and processing time before a push request is rejected. | Sync Push Service (Tranche 5) |
| B7 | **Push admission health-gating** — whether push requests are refused early when the destination or its dependencies are unhealthy. | Sync Push Service (Tranche 5) |
| B8 | **Alert-rule thresholds** — which conditions raise which severity, and to whom. | Observability / Operations Service |
| B9 | **PostgreSQL HA/DR standard** — the high-availability and disaster-recovery target (RPO/RTO) for the DAL's own database. | Reliability design, RSK register |
| B10 | **Confirmed DataSync throughput** — the measured sustained transfer rate, needed to validate the concurrency limits. | Sizing / performance validation |
| B11 | **Per-source file-watch / readiness contracts** — how each source signals that a batch is ready to read (related to the readiness-source question **C12** below). | Readiness onboarding |
| B12 | **CR-01 / CR-02 sign-off** — two Change Requests against platform design **v1.1**, agreed during requirements review but still awaiting formal approval: **CR-01** — the synchronous *push* path may serve a relational extract as **Parquet**, not only a file/object fetch (stories CS-008, CS-031); **CR-02** — **compression** is a shared capability on *both* the pull and push paths, not pull-only (story CS-010). | Requirements baseline closure |
| B13 | **v1.1 → v1.2 artefact alignment (Q-12)** — CR-01/CR-02 were agreed against design **v1.1**, but v1.1 was never updated, so the older v1.1 platform doc and the newer v1.2 user-stories/design now disagree on those two points. **Q-12** is the open item to reconcile the two documents so they say the same thing (a documentation-drift risk, not a code blocker). | Spec consistency |

---

## C. Stakeholder ownership & operating-model questions (engagement-level)

Still-Open items from [[open-questions]]. The *technology* is largely decided; what remains is
**who owns operating it** and the surrounding governance. These block go-live readiness, not the
code build itself.

| # | Question | Owner | Status note |
|---|----------|-------|-------------|
| C1 | Data classification process & ownership for **unstructured** data | Anand | Design metadata-driven (D18); operational ownership open |
| C2 | Data acquisition **data & process ownership** model | Anand | Not addressed since LLD |
| C3 | Encryption/tokenization **operational ownership** | Radha | Tech confirmed (D18/D27); ownership open |
| C4 | AWS Organization **SCP structure** for DAL + AI accounts | Remy | Not addressed in v1.1 |
| C5 | On-prem & AWS **key management** ownership | TISO | Mechanism = CyberArk/Conjur (D22); ownership open |
| C6 | On-prem & AWS **secret management** ownership | TISO | Same as C5 |
| C7 | Cloud resource **access model** — direct desktop vs EUC (WorkSpaces/Citrix) | — | WIP, not addressed in v1.1 |
| C8 | **Operating model / runbooks** for infra/job/data/security-compliance failures | Anand | Alerting defined (§14); human operating model open |
| C9 | **Code development, build & promotion** process (CI/CD) | Anand | Not addressed in v1.1 |
| C10 | Confirmed **performance/scale volumes** (OQ-01) | TBD | Needed for agent-pool + PostgreSQL sizing |
| C11 | **Catalog/lineage** expectations for landed data (OQ-03) — DAL registers lineage, or downstream-only? | TBD | — |
| C12 | Readiness source (OQ-07) — reuse the bank's existing ingestion-control framework (business-date control table) or per-source readiness tables? DAL polls directly or via Control-M dependency? | Data platform team | Determines readiness onboarding effort |
| C13 | **Intraday file arrivals** (OQ-09) outside a scheduled window needing event-driven pickup? | Data platform + source teams | Today undetected until next scheduled run |
| C14 | **Schema-baseline governance + alert recipients** (OQ-10) — who approves a new baseline, for which sources is BL-005 enabled, per-severity email lists, is email sufficient? | Data platform + data eng + observability | Feeds BL-005 enablement |

---

## D. Infrastructure / delivery-blocking questions

Concrete blockers captured in [[deliverables/findings]] that need an owner action/answer before
a real deployment.

| # | Question | Owner | Source |
|---|----------|-------|--------|
| D1 | Rotate the real RDS password and move it out of source into Secrets Manager / SSM — when and by whom? (hardcoded `db_password` default in `ocbc-data-acquisition-service/terraform`). | Infra / security | findings #9 |
| D2 | Who creates the consolidated `dataacq` database (and migrates/drops the old per-service DBs) on the real RDS instance before `terraform apply`? | Infra | findings #10 |
| D3 | When are the architecture diagrams redrawn to drop the excluded Airflow boxes (D16) and reconcile the 4-service vs 5-service depiction? | Architecture / docs | findings #2, #3 |
| D4 | BYOK KMS rotation runbook + rotations-remaining monitoring (manual, capped at 25) — who owns it? | Security / key management | findings #1 |
| D5 | Single non-prod (UAT-only, A17): how is the D21 on-prem-outage-resume guarantee validated, and production-scale load/soak testing done, before go-live? (RSK-01–RSK-05) | Delivery / test | findings #4, #5 |

---

## Resolved (for traceability — not action items)

- **A1 — SLA breach flag vs terminal status:** resolved 2026-08-11 — implemented as the terminal `SLA_BREACH` status per Detailed Design §6.1 (flag removed); `ocbc-cloud-sync` DD-B1.
- **A3 — Readiness poll design:** answered 2026-08-11 by the DAL design owner — readiness is a configured, parameterised `SELECT COUNT(*)` poll (bound date + status filter, ready when count ≥ expected), with the poll window and interval held per-pipeline in the configuration table; CS-021 outcomes stand (expiry → `READINESS_TIMEOUT` + alert; query-error retry per CS-016). Remaining is only per-pipeline value tuning at onboarding.
- **A4 — Retry & backoff design:** answered 2026-08-11 by the DAL design owner — retry schedule stored in the pipeline configuration table (base delay, multiplier, cap, max attempts), deterministic exponential backoff with **no jitter** (`delay = min(cap, base·2^attempt)`); CS-016 mechanism stands (transient → retry, permanent → fail, exhaustion → fail + alert + quarantine). The `TRANSIENT`/`PERMANENT` map seeds the table as defaults.
- **A5 — Business-date resolution ruling:** resolved 2026-08-11 as a design ruling — Epic G (CS-060/061/062) fully specifies the token set, the system-wide anchor date + scheduled Control-M roll-over (incl. ownership), and per-country calendars, so no design-owner ruling is needed. Remainders are delivery/operational only: the resolver build (now the **final Tranche 7**, split out of Tranche 3 on 2026-08-12) and calendar-data ownership (not open questions).
- **A7 — S3 source connector / ETag pre-read / multipart abort (CS-007):** resolved 2026-08-11 — implemented (config-selected S3 source with `ifMatch` ETag check; multipart upload with `AbortMultipartUpload`); DD-B2.
- **OQ-08 / Q-25 — scheduler contract:** resolved by the Scheduler Job Adapter (v1.3).
- **Q-15 — which stage decompresses landed content:** the DAL, AWS-side, post-transfer (Epic H, CS-063/064).
- **OQ-04 — service-to-service auth**, **OQ-06 — FinOps/cost attribution:** resolved in the v1.1 register.
- **#1 — orchestration engine:** Control-M trigger + in-service run driver (Temporal & Airflow excluded, v1.2).
- **#11 — non-prod OpenShift host:** UAT-only on existing on-prem cluster (A17).
- **D03 — microservice decomposition:** five-component model (DD-01–DD-15).

## Related

- [[open-questions]]
- [[synthesis/data-acquisition-open-decisions]]
- [[reference/cloud-sync-user-stories]]
- [[deliverables/findings]]
- [[synthesis/orchestration-service-mini-assessment]]
