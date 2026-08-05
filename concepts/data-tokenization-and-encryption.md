---
title: Data Tokenization and Encryption Strategy
category: concepts
tags: [aws, security, encryption, tokenization, ocbc, data-acquisition]
relationships:
  - target: "[[concepts/data-onboarding-orchestration-pipeline]]"
    type: related_to
  - target: "[[concepts/kms-byok-key-management]]"
    type: uses
sources: ["External: Mar 11 _Data-Acquisition-Service-LLD-NarrativeV1.0[63].pdf"]
summary: Four techniques OCBC's Security Service applies to protect data before it leaves on-prem — two reversible tokenization methods, one irreversible hash, and app-level encryption for unstructured files.
provenance:
  extracted: 0.88
  inferred: 0.1
  ambiguous: 0.02
base_confidence: 0.59
lifecycle: draft
lifecycle_changed: 2026-07-27
tier: core
created: 2026-07-27
updated: 2026-07-27
---

# Data Tokenization and Encryption Strategy

The on-prem **Security Service** (part of [[concepts/data-onboarding-orchestration-pipeline]]) applies classification-driven protection to every file before it is staged for cloud transfer. Protection technique is keyed off the source system's registered classification level and field-level sensitivity metadata.

## Techniques

1. **Format-Preserving Encryption (implied FF3-1, AES-256)** — reversible; produces a token in the same format as the original value so downstream systems relying on format don't break. A dedicated AES-256 FF3-1 key per source system is stored in on-prem Vault and synced to AWS Secrets Manager.
2. **SHA-256 HMAC Redaction (irreversible)** — for highly sensitive PII (NRIC, passport numbers) that must never be recoverable downstream. A source-specific HMAC secret key stays exclusively on-prem (never synced to AWS); a salt of `source_id + batch_date` prevents cross-source rainbow-table attacks. A separate on-prem mapping table allows retrieval if ever needed.
3. **Application-Level Encryption for unstructured files** — for PDFs, Word docs, images, audio/video classified CONFIDENTIAL/RESTRICTED that can't be field-tokenized. Uses **AES-256-GCM** (authenticated encryption) with a unique 96-bit IV per file per batch, prepended to the ciphertext. AAD binds the ciphertext to `source_id`, `batch_date`, and `file_path` to prevent ciphertext substitution.
4. **S3 Server-Side Encryption (baseline)** — all data at rest in S3 is additionally encrypted using SSE-KMS with customer-managed keys (see [[concepts/kms-byok-key-management]]), regardless of whether app-level encryption was also applied.

## AWS-Side Decryption

Because unstructured files are encrypted at the application level *in addition to* S3 SSE-KMS, AWS processing engines (Glue, Lambda, EMR, SageMaker) must decrypt in-memory before use — retrieving the AES-256 key from Secrets Manager and reconstructing the AAD from S3 object metadata tags. Noted compute overhead: AES-NI hardware acceleration decrypts a 1 GB file in under 2 seconds on a standard Lambda; Glue/EMR jobs need ~2× the compressed file size in executor memory for the decrypted plaintext, and a dedicated single-threaded decryption step is recommended at the start of each job DAG.

## Key Synchronisation: On-Prem Vault → AWS Secrets Manager

Triggered after each Security Service run via an EventBridge/Kafka-connector rule invoking a **Key Sync Lambda**:

1. Lambda authenticates to on-prem Vault via AppRole (5-minute single-use token) over Direct Connect.
2. **Reversible token mappings** are synced incrementally (delta only), paginated at 1,000 entries per Secrets Manager secret.
3. **FF3-1 keys** sync only on rotation; the old key version is retained for a 7-day grace period to let in-flight de-tokenization complete.
4. **Application encryption keys** sync only on rotation events, with the deprecated version similarly retained.
5. Every sync is logged to a `sync_audit_log` table and CloudTrail; sync failures block all downstream data movement until resolved.

The irreversible SHA-256 HMAC key is the one deliberate exception — it is never synced to AWS, by design.

## Metadata Tagging Discipline

Every file carries a tokenization manifest (streaming: embedded in Kafka message headers; batch: embedded in Parquet metadata + S3 object tags) recording which fields were tokenized, which technique was used, and the key version — giving downstream consumers and auditors a self-describing record of what protection was applied.

## Related

- [[concepts/data-onboarding-orchestration-pipeline]]
- [[concepts/kms-byok-key-management]]
- [[concepts/streaming-data-acquisition]]
- [[synthesis/data-acquisition-architecture-overview]]

## Sources

- External: Mar 11 _Data-Acquisition-Service-LLD-NarrativeV1.0[63].pdf
