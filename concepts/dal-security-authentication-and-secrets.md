---
title: DAL Security, Authentication and Secrets Management
category: concepts
tags: [ocbc, data-acquisition, security, cyberark, conjur, entra-id]
relationships:
  - target: "[[entities/cloud-data-acquisition-service]]"
    type: extends
  - target: "[[concepts/data-tokenization-and-encryption]]"
    type: related_to
  - target: "[[concepts/kms-byok-key-management]]"
    type: related_to
sources: ["External: OCBC Data Acquisition Platform on AWS - v1.1.pdf", "External: OCBC Data Acquisition - Cloud Sync User Stories.md", "External: OCBC Data Acquisition Platform on AWS - v1.3.md"]
summary: The DAL's confirmed identity, secrets, and encryption model — MS Entra ID for external/human callers, CyberArk Vault via Conjur for runtime secret resolution, and CMK-KMS at S3 as the sole encryption-at-rest layer — plus (v1.3) the two candidate mechanisms under evaluation for on-premises-to-AWS credential vending (DI-06).
provenance:
  extracted: 0.9
  inferred: 0.1
  ambiguous: 0.0
base_confidence: 0.74
lifecycle: draft
lifecycle_changed: 2026-07-31
tier: core
created: 2026-07-28
updated: 2026-07-31
---

# DAL Security, Authentication and Secrets Management

Design v1.1 confirms the DAL's full authentication model (§13), refining and superseding the more general "on-prem secrets vault" language in the earlier LLD and UC-1 narrative. **This directly informs [[synthesis/data-acquisition-open-decisions]] alignment-matrix items #6/#7 (key/secret management ownership).**

## Identity Providers

| Provider | Role | Decision |
|---|---|---|
| **MS Entra ID** | Authenticates externally-initiated DAL API access — Control-M, event-trigger coordinators, sync-push callers, and human/operator access (SAML/OIDC + RBAC: Admin/Operator/Viewer) | D14 |
| **CyberArk Vault, accessed via Conjur** | Runtime resolution of source-system and database credentials by reference key; no raw credentials ever stored in the Source Registry | D22 |

## The 8 Authentication Methods (§13.4)

| # | Method | Used for |
|---|---|---|
| 1 | Token-based (MS Entra ID, OAuth2 client-credentials) | Control-M/coordinator → Spring Cloud Gateway; human/operator access; EventBridge API Destination completion callback |
| 2 | Network-enforced trust, no workload auth (OpenShift `NetworkPolicies`) | Same-namespace pod-to-pod calls (Gateway, Orchestration, Integration, Control, Security, Temporal) |
| 3 | Workload-identity authentication to CyberArk Conjur | Every DAL pod resolving a database or source secret by reference key |
| 4 | Database password authentication (PostgreSQL) | Each service's dedicated least-privilege DB account, password from Conjur (method 3) |
| 5 | Source-native credential authentication (per protocol) | Oracle DB password (read-only), WFI OAuth/token, WFTS SSH key/SMB/NFS credential, Dell ECS S3 access keys — all vault-resolved |
| 6 | Object-storage credential authentication (S3-compatible) | Per-service least-privilege identity to the two on-prem zones (Integration writes control-zone; Control reads/updates; Security promotes; DataSync reads transfer-ready only) |
| 7 | AWS IAM request signing (SigV4) | On-prem → AWS calls (EventBridge `PutEvents`, S3 push writes); AWS-managed components use IAM service/execution roles |
| 8 | Authenticated TLS/OTLP + Observability Platform RBAC | On-prem OTel collector → AWS OTel Gateway; operator access to dashboards/logs/traces |

Every workload has a dedicated identity and least-privilege authorization throughout — there is no shared service account spanning multiple components.

## Encryption Scope (§13.2, D18)

| Scope | Method | Detail |
|---|---|---|
| In transit | TLS 1.3+ over Direct Connect | Required for all on-prem↔AWS traffic |
| At rest (S3) | SSE-KMS with the OCBC customer-managed key (CMK) | **Sole encryption layer for landed data** — enforced on every `PutObject` |
| At rest (PostgreSQL) | Storage/disk encryption | OCBC's on-prem standard in production; AWS-managed encryption for the UAT interim AWS-hosted stores |
| At rest (on-prem staging zones) | **None required (D18)** | Per explicit customer direction — no at-rest encryption on `cloud-sync-<src-system>-control-zone` or `cloud-sync-<src-system>-zone` |

This confirms and sharpens what the earlier UC-1 narrative already stated ("No encryption is applied on-premise... CMK KMS at the S3 destination is the sole encryption layer... AWS Direct Connect provides TLS encryption in transit") — v1.1 makes it a numbered, binding decision (D18) rather than a narrative aside.

## Governance (§13.3)

Classification, PII flag, retention, and KMS key are held per source in `source_governance` and applied by the Security Service before the zone switch (pull) or the direct write (push). **A pipeline cannot reach the transfer/write step without a KMS key and a security sign-off flag.** Classification is metadata-driven; content scanning/DLP is explicitly out of scope this phase.

## What This Resolves vs. What's Still Open

- **Resolved:** the secrets *vault product* (CyberArk Vault via Conjur, D22) and the *authentication provider* (MS Entra ID, D14) are now both confirmed and numbered decisions, with a full method-by-method interaction matrix (§13.1). The former "on-prem secrets vault" and "Vault → Secrets Manager" language in earlier ingested pages should be read as referring to this same CyberArk Conjur mechanism.
- **Still open / delivery items:** the operational *ownership* model for running key/secret management day to day (who administers Conjur safes, who approves new source onboarding secrets) is not addressed by v1.1 — it remains a governance/process question, tracked in [[synthesis/data-acquisition-open-decisions]]. Configuring the on-premises temporary-AWS-credential vending mechanism (method 7) is an explicit delivery item (DI-06) — v1.3 narrows this to a choice between two candidate mechanisms, detailed below.

## DI-06 — On-Premises to AWS Credential Vending (v1.3, mechanism not yet selected)

Two DAL interactions originate on-premises and target AWS — Orchestration's `PutEvents` call (pull path) and the Sync Push Service's direct `PutObject` (push path) — from a pod with no EC2 instance profile, no instance metadata service, and no cluster identity token AWS trusts by default. v1.3 states the requirement and two candidate mechanisms; **the choice is deferred to task 4.2.3**:

| | Option 1 — Entra ID federation to AWS STS | Option 2 — IAM Roles Anywhere |
|---|---|---|
| How identity is proven | Pod exchanges its own Entra ID app-registration token at STS via `AssumeRoleWithWebIdentity`; AWS is registered as an OIDC provider per DAL account | Pod presents an X.509 client certificate (OCBC PKI) to a Roles Anywhere trust anchor per DAL account |
| Reuses existing OCBC building blocks | Extends the already-approved Entra ID integration (D14) | Reuses OCBC's enterprise PKI, but adds a certificate lifecycle (issuance/renewal/revocation) per replica |
| Main consideration | Adds AWS as an Entra relying party — needs identity-team approval; token audience/lifetime must be pinned tightly | No IdP-reachability dependency, but introduces certificate distribution/rotation as new operational work |

**Fixed regardless of the choice:** a distinct AWS role per workload (Orchestration: `PutEvents` only; Sync Push: `PutObject` narrowed per request by a session policy to the resolved bucket/prefix/CMK), separate trust registration in each DAL account (non-production and production, so a non-prod credential can never reach a prod bucket/key), no long-lived IAM access keys on-premises, and a distinguishable `CREDENTIAL_VENDING_FAILED` audit error rather than a generic AWS error. See [[reference/data-acquisition-platform-v1.3]] for the full requirements list.

## Related

- [[entities/cloud-data-acquisition-service]]
- [[concepts/data-tokenization-and-encryption]] — the separate encryption/tokenization *techniques* used at the AWS/data-content layer
- [[concepts/kms-byok-key-management]] — BYOK CMK creation/rotation for the S3-side key referenced here
- [[synthesis/data-acquisition-open-decisions]]
- [[reference/data-acquisition-platform-v1.1]]
- [[reference/data-acquisition-platform-v1.3]]

## Sources

- External: OCBC Data Acquisition Platform on AWS - v1.1.pdf
- External: OCBC Data Acquisition - Cloud Sync User Stories.md
- External: OCBC Data Acquisition Platform on AWS - v1.3.md
