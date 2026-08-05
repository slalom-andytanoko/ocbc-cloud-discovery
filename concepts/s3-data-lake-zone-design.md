---
title: S3 Data Lake Zone Design
category: concepts
tags: [aws, s3, data-lake, ocbc, data-acquisition]
relationships:
  - target: "[[entities/cloud-data-acquisition-service]]"
    type: related_to
sources: ["External: Mar 11 _Data-Acquisition-Service-LLD-NarrativeV1.0[63].pdf"]
summary: OCBC's data acquisition account uses three S3 zones (Gold/Bronze/Egress) with a fixed bucket/prefix naming convention and DLP considerations for privileged-user uploads.
provenance:
  extracted: 0.85
  inferred: 0.15
  ambiguous: 0.0
base_confidence: 0.59
lifecycle: draft
lifecycle_changed: 2026-07-27
tier: supporting
created: 2026-07-27
updated: 2026-07-27
---

# S3 Data Lake Zone Design

The AWS Data Acquisition account organises S3 storage into three zones, each potentially spanning multiple buckets.

## Zones

| Zone | Description | Sample lifecycle policy |
|---|---|---|
| **Gold Acquisition Zone** | Copy of already-curated datasets from on-prem EDW/Cloudera — bridges the AI platform and other advanced use cases until EDW/Cloudera is modernised | After 1 year → S3 Infrequent Access; after 2 years in IA → Glacier |
| **Bronze Zone** | Raw, unprocessed data ingested into the lakehouse | Retention policy set per the source registry |
| **Data Egress Zone** | Staging zone for batch data going back on-prem to downstream systems | Retention policy agreed with the downstream data owner |

## Bucket Naming

```
s3://companyname-goldacqzone-<awsregion>-<awsaccount>-<classification>-<env>/
s3://companyname-bronzeacqzone-<awsregion>-<awsaccount>-<classification>-<env>/
s3://companyname-egresszone-<awsregion>-<awsaccount>-<classification>-<env>/
s3://companyname-logging-<awsregion>-<awsaccount>-<env>/
s3://companyname-artefacts-<awsregion>-<awsaccount>-<env>/
```

## Prefix Design

- Structured: `/source/source_region/database/table/year=yyyy/month=mm/day=dd/`
- Unstructured: `/source/source_region/<obj_type>/<domain>/ddmmyyyy/`

## Sensitive Data Handling in the Lakehouse

All data at rest is S3 SSE-KMS encrypted with customer-managed keys by default (see [[concepts/kms-byok-key-management]]). Two residual risk scenarios are called out explicitly in the source document:

- Privileged users may inadvertently upload highly sensitive data directly to an S3 bucket.
- Jobs may write decrypted sensitive data into buckets that should remain tokenized.

Mitigations proposed: mandate access only via Amazon WorkSpaces (virtual desktop, no direct data egress path), enforce SSE-KMS (CMK) as the default on every bucket, define SCP guardrails (**OCBC decision pending**), and optionally deploy a DLP solution such as AWS's *Sensitive Data Protection on AWS* reference solution (automated PII discovery/classification/labeling across accounts, no manual tagging required).

## Related

- [[entities/cloud-data-acquisition-service]]
- [[concepts/kms-byok-key-management]]
- [[concepts/data-tokenization-and-encryption]]
- [[synthesis/data-acquisition-architecture-overview]]
- [[synthesis/data-acquisition-open-decisions]] — SCP guardrail structure is an open decision (owner: Remy)

## Sources

- External: Mar 11 _Data-Acquisition-Service-LLD-NarrativeV1.0[63].pdf
