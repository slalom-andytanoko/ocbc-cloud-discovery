# Team Input — Commentary Register

Structured team opinions, decisions, and context that should shape the wiki and deliverables.
This is the **highest-authority source** for deliverable generation (see the
`team-commentary-authority` rule). Newest entries at the top.

Format:

```
### <date> — <person>
**Context:** <finding / wiki page / open question / topic>
**Input:** <the opinion, decision, or context>
**Impact:** <how this should influence deliverables>
```

---

### 2026-08-11 — Andy

**Context:** [[questions]] A6 — housekeeping / retention values (CS-059, open question Q-03)
**Input:** Retention values are to be held **in the configuration table** (per-source / per-zone),
consistent with CS-059's "per-source retention period configured for each zone" — the same
config-table pattern as A3 (readiness) and A4 (retry). This is a **storage** decision only; the
DAL owner does **not** set the actual retention periods — those remain a **compliance** decision
(Q-03).
**Impact:** A6 storage/mechanism is resolved (config-table driven); A6 now carries **proposed
recommended values** pending **compliance sign-off** (not fully open). Recommended config-table seeds:
`audit_retention_days` = **90 d** (run/run_task/run_event/push_run, hot Postgres), `dedup_window_days`
(CS-015) = **30 d**, `staging_zone_retention_days` = **7 d**, `transfer_ready_zone_retention_days` =
**7 d**, `max_replay_latency_days` = **30 d**. Constraint holds: audit 90 ≥ zone 7 + replay 30 = 37.
Long-term regulatory archival is **separate** and compliance-owned: `regulatory_archive_years` ≈
**7 yr** (placeholder — compliance to confirm against the bank's records schedule), archived out of
the hot store to the data lake / cold storage. Owner on all values = compliance, not the DAL owner.

### 2026-08-11 — Andy

**Context:** [[questions]] A4 — retry & backoff taxonomy (CS-016)
**Input:** The retry schedule is stored **in the pipeline configuration table** (per-pipeline,
env-default fallback) — base delay, multiplier, cap, max attempts — and backoff is **deterministic
exponential with no jitter**: `delay = min(cap, base · 2^attempt)`. **No jitter.** CS-016's
mechanism otherwise stands (transient → retry to the configured limit + checkpoint resume;
permanent → immediate fail; exhaustion → fail + alert CS-043 + quarantine CS-042; on-demand not
retried past the response limit).
**Impact:** A4 is closed as a design ruling. Build the retry engine as config-table driven with **no
jitter**. Seed the config table with the proposed defaults (base 5s, multiplier 2, cap 300s, max
attempts 5) and the `TRANSIENT`/`PERMANENT` error-class map as defaults; values are per-pipeline
tunable. Do **not** implement full-jitter backoff.

### 2026-08-11 — Andy

**Context:** [[questions]] A3 — readiness poll-window / give-up policy (CS-021)
**Input:** Readiness is a **configured, parameterised `SELECT COUNT(*)` poll**. The poll **window and
interval live in the configuration table** (per-pipeline, env-default fallback). The query is a
`COUNT(*)` against the source's control/batch table with a **bound date** (`:batch_date`) and a
**status filter** (`Status IN ('COMPLETE','DONE', …)`); the source is **ready when the count ≥ the
expected value** (default `≥ 1`). CS-021's outcomes stand: poll-window expiry → `run.fail()` with
`READINESS_TIMEOUT` + alert (CS-043), no auto-retry (operator replays, CS-041); a readiness *query*
error is retried per CS-016 within the window.
**Impact:** A3 is closed as a design ruling. Build the readiness check as a config-table-driven
`COUNT(*)` poll (window/interval/query/expected-count columns). This concretises CS-021's "any query
that returns a single comparable value" as a count of rows in a ready state — record it that way in
design.md / the Source Registry schema. Per-pipeline values are set at onboarding.
