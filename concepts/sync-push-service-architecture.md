---
title: Sync Push Service Architecture (DAL Mode 2)
category: concepts
tags: [ocbc, data-acquisition, aws, sync-push, scalability]
relationships:
  - target: "[[entities/cloud-data-acquisition-service]]"
    type: extends
  - target: "[[concepts/temporal-io-workflow-orchestration]]"
    type: contradicts
  - target: "[[concepts/source-registry-and-audit-data-model]]"
    type: uses
sources: ["External: OCBC Data Acquisition Platform on AWS - v1.1.pdf", "External: OCBC Data Acquisition - Cloud Sync User Stories.md"]
summary: A new, dedicated, stateless, horizontally-scaled service (D24) serves the DAL's synchronous push mode — separate from the async Orchestration Service and using no workflow engine.
provenance:
  extracted: 0.85
  inferred: 0.15
  ambiguous: 0.0
base_confidence: 0.72
lifecycle: draft
lifecycle_changed: 2026-07-28
tier: core
created: 2026-07-28
updated: 2026-07-28
---

# Sync Push Service Architecture (DAL Mode 2)

Design v1.1 introduces a component not present in the earlier (11 Mar 2026) LLD: a dedicated **Sync Push Service** serving the synchronous-push interface mode (Mode 2), separate from the Orchestration Service that owns the asynchronous scheduled-pull mode (Mode 1). This is decision **D24**.

## Why a separate service (D24)

The push path is a long-lived, blocking request/response workload — the opposite profile to the async intake. Co-locating it with the Orchestration Service would let a burst of concurrent `/sync/push` calls exhaust the shared request tier and starve the pull-mode endpoints. Splitting it out:
- isolates thread pools, connection pools, and cluster resources from Orchestration and Temporal;
- lets the push API scale horizontally across replicas rather than within one process;
- is explicitly framed as "the one physical boundary the design commits to now", ahead of the fuller microservice decomposition still deferred under D03.

## Deployment Topology

A stateless OpenShift `Deployment` in its own `dal-sync-push` namespace (same cluster as the async services, isolated by a `ResourceQuota`/`LimitRange` so it cannot starve Orchestration/Temporal at the node level). Callers reach it through a `Service`/`Route` that load-balances across all healthy replicas — no sticky sessions.

**Two scaling axes:**

| Axis | Mechanism | Bounded by |
|---|---|---|
| Scale out (primary) | Replicas behind the Service/Route, autoscaled by an HPA (KEDA-driven) | `maxReplicas`; PostgreSQL connections via PgBouncer; source/DX capacity |
| Scale up per pod | Java 25 virtual threads + streaming multipart writes + local admission control | Pod CPU/memory limits; per-pod in-flight cap |

Each request runs on a virtual thread so a blocking source fetch or S3 multipart upload doesn't park an OS thread. A per-pod semaphore caps in-flight requests and returns `429`/`503 Retry-After` when saturated. The HPA scales on a custom load metric (in-flight request count / admission-queue depth) rather than CPU, since push spends most of its time in I/O wait.

## Why Horizontal Scale-Out Is Safe

- **Statelessness** — no pod holds per-request state another pod needs.
- **Idempotency across replicas** — a `UNIQUE` constraint on `idempotency_key` in the audit table with an insert-first pattern: whichever replica wins the insert owns the run; a losing replica returns the original terminal result (`409`). This is required because two retries with the same key can land on different pods, so in-memory dedupe cannot work.
- **Database connection ceiling** — total connections = replicas × per-pod pool size, which can exceed `max_connections` as the fleet grows, so PostgreSQL is fronted by **PgBouncer** (transaction pooling) with small per-pod pools.
- **Graceful scale-down/rollout** — `terminationGracePeriodSeconds` ≥ request timeout, a `preStop` hook plus readiness gating drains in-flight requests, and a `PodDisruptionBudget` prevents autoscaling/deploys cutting off too many pods at once.

## No Temporal, No Staging Zones

Push is fail-fast with no durable resume (ties to D21's outage behaviour, §5.1) — the caller retries idempotently — so the service **embeds no workflow engine**, keeping pods light and fast to start for autoscaling. It also has **no on-premises staging and no DataSync step**: it embeds the Integration, Control, and Security logic as **in-process libraries** and writes directly to S3. See [[concepts/temporal-io-workflow-orchestration]] for the contrasting pull-mode design.

## Step Sequence (all in one pod)

| Step | Actor | Action | Audit status |
|---|---|---|---|
| 0 | Caller → Sync Push Service | `POST /sync/push` (Entra ID auth); admission control; create `run_id` + `trace_id`; insert audit row on `UNIQUE idempotency_key`; resolve config | `INITIATED` |
| 1 | Integration lib | Fetch/receive the data via the relevant connector (streaming) — including, per **CR-01**, a relational (Oracle) extract fetched over JDBC and written as Parquet, not just a file/object fetch | `RECEIVED` |
| 2 | Control lib | Validate against thresholds (bounded, fast) | `VALIDATED` |
| 3 | Security lib | Classify, tag `target_tier` | `CLASSIFIED` |
| 4 | → S3 | Direct streaming multipart write to the resolved bucket/prefix with CMK KMS | `WRITING` |
| 5 | — | Confirm the S3 write and checksum (e.g. `HeadObject` + stored ETag/checksum) before returning success; close the run | `COMPLETED`/`FAILED` |
| 6 | → caller | Return terminal result (success + location, or error) within the response timeout | — |

**Interface contract:** `POST /sync/push` → `{ target, source_ref | payload_ref, idempotency_key, classification_hint? }`; responses `200 { run_id, status: COMPLETED, s3_uri, bytes, checksum }`, `409` duplicate idempotency key (returns the original result), `408`/`504` on timeout.

## Change Requests Against the Base Design (§8 of the User Stories doc)

Two confirmed change requests extend v1.1 slightly, both affecting the push path:

| ID | Change | Consequence |
|---|---|---|
| **CR-01** | The synchronous push path can serve a relational (Oracle) extract, not only a file/object fetch — Parquet is produced on both paths whenever the input is a relational extract | The Sync Push Service holds a JDBC connection for the duration of a synchronous request, so payload-size/duration limits (open question Q-06) matter more, and its PgBouncer/connection budget must account for source-database connections as well as audit-store connections |
| **CR-02** | Compression is a shared capability applied on both paths, not pull-only | Compression sits inside the push response budget, motivating a skip-threshold open question (Q-01/Q-06) |

## Outage Behaviour

No on-prem staging exists on this path, so an AWS/Direct Connect outage makes the direct S3 write fail fast; the caller retries idempotently once AWS returns (D21, §5.1) — contrast with the pull path, which holds at the `SECURED` checkpoint and resumes via Temporal.

## Related

- [[entities/cloud-data-acquisition-service]]
- [[concepts/temporal-io-workflow-orchestration]]
- [[concepts/source-registry-and-audit-data-model]]
- [[reference/cloud-sync-user-stories]]
- [[reference/data-acquisition-platform-v1.1]]

## Sources

- External: OCBC Data Acquisition Platform on AWS - v1.1.pdf
- External: OCBC Data Acquisition - Cloud Sync User Stories.md
