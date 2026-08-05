---
title: KMS BYOK Key Management
category: concepts
tags: [aws, kms, byok, encryption, ocbc]
relationships:
  - target: "[[concepts/data-tokenization-and-encryption]]"
    type: related_to
  - target: "[[concepts/s3-data-lake-zone-design]]"
    type: uses
sources: ["External: Mar 11 _Data-Acquisition-Service-LLD-NarrativeV1.0[63].pdf", "External: image002.png", "External: OCBC Data Acquisition Platform on AWS.md"]
summary: OCBC brings its own key material into AWS KMS (BYOK); rotation is manual and capped at 25 on-demand rotations per key. Superseded (v1.4, D27): one customer-managed key per AWS account, not per source system.
provenance:
  extracted: 0.82
  inferred: 0.15
  ambiguous: 0.03
base_confidence: 0.59
lifecycle: draft
lifecycle_changed: 2026-08-05
tier: supporting
created: 2026-07-27
updated: 2026-08-05
---

# KMS BYOK Key Management

> **Superseded (v1.4, 2026-08-04 — new D27):** confirmed with the customer that each DAL AWS account holds a **single** customer-managed key (CMK) for landed data, not one CMK per source system as originally modelled below. `source_governance` drops its per-source KMS key field entirely; segregation between sources/applications now rests on S3 prefix/bucket boundaries plus IAM, not per-source key scoping. Key provisioning, rotation, and key-material origin remain customer-owned. The BYOK import mechanics and the 25-rotation cap below still apply — they now apply to the one account-level key rather than to many per-source keys. See [[reference/data-acquisition-platform-v1.5]].

Every DataSync task writes to S3 using a **Customer Managed Key (CMK)**, originally modelled as source-specific and provisioned during source onboarding, with the per-source DataSync IAM role scoped exclusively to `kms:GenerateDataKey` / `kms:Decrypt` on that one CMK. ^[superseded — see note above]

## BYOK Process

OCBC imports its own key material rather than letting AWS KMS generate it (key origin: `EXTERNAL`):

1. Create a KMS key with `Origin: EXTERNAL` (no key material yet).
2. Download a wrapping public key + import token from AWS KMS (valid 24 hours).
3. Encrypt (wrap) the locally-generated 256-bit key material with the wrapping public key.
4. Import the wrapped key material + import token; key state moves `PendingImport → Enabled`.
5. Optionally set an expiration — if it lapses, AWS KMS deletes the material and the key becomes unusable until reimported.

**Durability is OCBC's responsibility**: AWS does not persist imported key material to any storage medium, so OCBC must retain the only failsafe copy (recommended: an external HSM), alongside a reference to the KMS key ARN and key material ID.

## Key Rotation — Manual, Capped at 25

**Automatic key rotation is not supported for BYOK keys.** OCBC must rotate on-demand:

1. Get new import parameters (wrapping key + token) for the *same* key.
2. Generate new 256-bit key material locally (retain both old and new versions).
3. Wrap and import the new material into the same KMS key.
4. Call `rotate-key-on-demand` to activate the new version; the old version is retained automatically for decrypting existing ciphertext.

A given KMS key supports a **maximum of 25 on-demand rotations** — after that, a new KMS key must be created and referenced going forward (via alias repointing, per the "Creating a new key" operational flow in the source). ^[inferred] (flagged here as an operational constraint worth tracking over the life of the engagement.)

## IAM Model

- **Key administrators** (manage the key) are separated from **key users** (use the key in crypto operations) via IAM policy + key policy — every KMS key has exactly one key policy.
- **S3 integration** uses SSE-KMS; **S3 Bucket Keys** are recommended to reduce per-request KMS calls (and cost) — a short-lived bucket-level key is cached in S3 and used to derive data keys for new objects.
- AWS Config's `s3-default-encryption-kms` rule can detect buckets created without KMS encryption.

## Related

- [[concepts/data-tokenization-and-encryption]]
- [[concepts/s3-data-lake-zone-design]]
- [[entities/cloud-data-acquisition-service]]
- [[synthesis/data-acquisition-open-decisions]]

## Sources

- External: Mar 11 _Data-Acquisition-Service-LLD-NarrativeV1.0[63].pdf
- External: image002.png (references CMK usage in the cloud sequence flow)
