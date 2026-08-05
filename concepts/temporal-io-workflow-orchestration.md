---
title: Temporal.io Workflow Orchestration (Historical, Superseded in v1.2)
category: concepts
tags: [temporal, orchestration, ocbc, data-acquisition, aws]
relationships:
  - target: "[[entities/cloud-data-acquisition-service]]"
    type: uses
  - target: "[[concepts/data-onboarding-orchestration-pipeline]]"
    type: extends
  - target: "[[concepts/sync-push-service-architecture]]"
    type: contradicts
sources: ["External: OCBC Data Acquisition Platform on AWS - v1.1.pdf", "External: OCBC Data Acquisition Platform on AWS - v1.2.md"]
summary: Historical v1.1 design note: Temporal.io (self-hosted) was previously selected for scheduled-pull orchestration, but v1.2 removes Temporal in favor of an in-service orchestration run driver.
provenance:
  extracted: 0.9
  inferred: 0.1
  ambiguous: 0.0
base_confidence: 0.75
lifecycle: draft
lifecycle_changed: 2026-07-28
tier: core
created: 2026-07-28
updated: 2026-07-29
---

# Temporal.io Workflow Orchestration (Historical, Superseded in v1.2)

## Superseded Status

This page is retained for historical traceability to **v1.1** decisions. In **v1.2 (2026-07-28)**, Temporal.io is removed and durable execution is implemented as an orchestration run driver inside the Orchestration Service backed by DAL PostgreSQL. See [[reference/data-acquisition-platform-v1.2]].

Design v1.1 of the Data Acquisition Layer (DAL) confirms **Temporal.io, self-hosted on Red Hat OpenShift**, as the durable-execution engine behind the Orchestration Service's scheduled-pull path (Mode 1). This is decision **D04**, and it directly resolves the orchestration-tooling ambiguity previously tracked as alignment-matrix item #1 in [[synthesis/data-acquisition-open-decisions]].

## Why Temporal (D04)

The run lifecycle needs durable timers (readiness poll windows, SLA deadlines), per-step retries with backoff, and crash-recovery. Temporal provides these natively and is the customer's stated preference. It persists to a **dedicated PostgreSQL store**, kept separate from the Source Registry/audit database (D05), so Temporal's high-write workflow-history churn doesn't contend with the config/audit workload.

## Apache Airflow is explicitly excluded (D16)

> "Apache Airflow is not used in the DAL on-premises setup... Confirmed not required. Temporal (D04) and Control-M cover scheduling and orchestration."

This is a hard, explicit design decision in v1.1 (dated 2026-07-24). It directly contradicts the previously-ingested LLD narrative (v1.0, 11 Mar 2026) and the architecture diagrams (`data acquisition.pptx`, `Data Aqusition.png`), both of which show **Apache Airflow** running on the on-prem Red Hat OpenShift cluster in the Production box. See the "Diagram vs. current design" note below and [[deliverables/findings]].

## Division of labour: Control-M vs. Temporal

| Concern | Owner |
|---|---|
| External scheduling (cron-like fire time, e.g. daily 04:00 SGT) | **Control-M** — fires the job, calls `POST /orchestration/runs/initiate`, logs the returned `run_id`, then is "fire-and-forget" (no polling, no callback) |
| Durable run lifecycle (readiness timers, poll-window expiry, step retries, checkpoint/resume, SLA-deadline timers) | **Temporal.io** — drives every state transition after Control-M's initial call |

Control-M passes only `source_id`/`pipeline_id`, `batch_date`, and `trigger_ref` — all other configuration (SQL, JDBC connection, SLA deadline, target tier, poll intervals) resolves from the Source Registry, so onboarding a new source is a registry change, not a Control-M job change.

## Persistence Store Placement (§9.7.1)

Temporal's server writes to its persistence store on every workflow task, timer fire, and history event — the server-to-store round trip is on Temporal's hot path. Two placements were evaluated against the availability objective **D21** (on-prem DAL must keep operating during an AWS outage):

| Option | Description | Decision |
|---|---|---|
| **A — on-premises** (chosen for production) | Dedicated PostgreSQL co-located with the Temporal server on-prem, separate from the config/audit DB | **Selected.** Lowest latency; orchestration keeps running during a Direct Connect/AWS outage; isolates Temporal's write-heavy history from config/audit |
| B — AWS-hosted (RDS/Aurora) | Temporal server on-prem, store in AWS | **Rejected for production** — every persistence operation would cross Direct Connect, adding latency to every workflow transition/timer and creating a hard dependency on DX/AWS health, which violates D21 |

**Interim exception:** in non-production (UAT), the Temporal store (and the config/audit store) are hosted in the AWS non-prod Data Acquisition account, because there is no on-premises UAT database placement yet (§7.4, A17). This means the D21 outage/resume guarantee is only representative in production (or in UAT once its databases move on-prem) — tracked as risk **RSK-05** in Appendix E.

Temporal officially supports PostgreSQL 12+ (tested against 13–16); Advanced Visibility can run on the same store from Temporal Server 1.20+ without a dedicated Elasticsearch instance at current volumes.

## Checkpoint / Resume Behaviour (ties to D21, §5.1)

For the scheduled-pull mode, when AWS or Direct Connect is unavailable:

1. The run proceeds fully on-prem through readiness, extraction/pickup, validation, classification, and promotion to the transfer-ready zone (reaching the `SECURED` state).
2. The next step — `PutEvents` to EventBridge — needs AWS, so **Temporal holds the run at the `SECURED` checkpoint**, retrying with backoff. Nothing is lost; the batch is safely staged on-prem.
3. When AWS is reachable again, **Temporal resumes the same run from its checkpoint** — no re-extraction, no duplicate landing (idempotent on `run_id`).

This is why Temporal is described as providing "resumable checkpoints after a crash" — the same mechanism covers both process crashes and AWS/Direct Connect outages.

## No Temporal on the Push Path (D24)

The synchronous-push mode (Mode 2, served by the dedicated Sync Push Service) is fail-fast with no durable resume — see [[concepts/sync-push-service-architecture]]. It deliberately embeds **no workflow engine**, since a blocking synchronous request has no need for timers or checkpointed resumption; retry is the caller's responsibility via the idempotency key.

## Diagram vs. current design (documentation staleness)

The `data acquisition.pptx` architecture slides ("Cloud Data Acquisition (Unstructured Data)" and "Data Acquisition Service (Structured Batch Sources)") both show an **Apache Airflow** logo/box wrapping the on-prem Red Hat OpenShift Production environment — predating the D04/D16 decision to standardise on Temporal.io + Control-M instead. These diagrams have not yet been refreshed to reflect the current (v1.1) design. Treating the diagrams as a literal current-state build spec would be a mistake; the written v1.1 decisions (D04, D16) are the authoritative source. See [[deliverables/findings]].

## Related

- [[entities/cloud-data-acquisition-service]]
- [[concepts/data-onboarding-orchestration-pipeline]] — full run state machine and step sequence
- [[concepts/sync-push-service-architecture]] — the no-Temporal push path
- [[synthesis/data-acquisition-open-decisions]] — D01–D24 decision register
- [[reference/data-acquisition-platform-v1.1]]
- [[reference/data-acquisition-platform-v1.2]]

## Sources

- External: OCBC Data Acquisition Platform on AWS - v1.1.pdf
- External: OCBC Data Acquisition Platform on AWS - v1.2.md
