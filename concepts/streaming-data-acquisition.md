---
title: Streaming Data Acquisition (Confluent Kafka)
category: concepts
tags: [aws, kafka, confluent, streaming, ocbc, data-acquisition]
relationships:
  - target: "[[entities/cloud-data-acquisition-service]]"
    type: derived_from
  - target: "[[concepts/data-tokenization-and-encryption]]"
    type: uses
sources: ["External: Mar 11 _Data-Acquisition-Service-LLD-NarrativeV1.0[63].pdf"]
summary: OCBC's streaming ingestion path uses on-prem Confluent Kafka, Cluster/Schema Linking to Confluent Cloud on AWS, and PrivateLink connectivity — a distinct architecture from the batch DataSync path.
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

# Streaming Data Acquisition (Confluent Kafka)

Unlike the batch structured/unstructured path (see [[concepts/data-onboarding-orchestration-pipeline]]), streaming sources flow through on-prem Confluent Kafka and are mirrored into Confluent Cloud on AWS.

## Pipeline

1. **Integration Service (Kafka Consumer)** — subscribes to enterprise Confluent topics per source, with **consumer-group isolation per source** to avoid offset interference. Performs schema extraction/fingerprinting against the Confluent Schema Registry on every message. Wraps each message in a canonical `StreamingIngestionEnvelope` (envelope_id, source_id, topic, partition, offset, timestamps, schema_version/fingerprint, payload, and classification tags). Breaking schema drift routes to a Dead Letter Topic; additive drift WARNs and auto-evolves the schema if compatibility mode allows. Implements consumer back-pressure (pause/resume) and retry-with-backoff before DLT routing.
2. **Security Service** — applies the same field-level tokenization as the batch path (see [[concepts/data-tokenization-and-encryption]]), converts JSON payloads to **Avro**, and applies **Snappy compression** (default; Gzip configurable per source for higher ratio). A tokenization manifest is embedded directly in Kafka message headers.
3. **Replication to Confluent Cloud on AWS** — uses **Confluent Cluster Linking**, a broker-level, offset-preserving mirroring feature (no separate replication process), giving sub-second latency. Mirror topics preserve the source topic name (`cloud-sync-<source-id>-zone`). **Confluent Schema Linking** runs alongside it to replicate Avro schema subjects from on-prem to the Confluent Cloud Schema Registry.

## Network Path: PrivateLink, Not Direct Connect

The streaming path uses a different network pattern than the DataSync batch path:

```
Workload VPCs → Transit Gateway → VPC Endpoint → AWS PrivateLink → Confluent
Confluent → AWS PrivateLink → VPC Endpoint → NLB → EC2 / S3 / RDS (workload accounts)
```

Key components: a **Common SaaS Service Account** acting as a central hub (NLB + VPC endpoint), a **Confluent AWS Account** that initiates connections, a shared **Private Hosted Zone** (distributed to workload accounts via AWS Resource Access Manager), and an **AWS Transit Gateway** as the central routing hub. Benefit: a single Confluent endpoint attached to an NLB can reach many AWS services, minimising the number of Confluent-side PrivateLink endpoints required. ^[inferred] (diagram + prose synthesis)

## Open Item

The source document flags: *"check with Confluent for optimal connectivity architecture"* — the network configuration steps are provided as a starting point, not a finalised design.

## Related

- [[entities/cloud-data-acquisition-service]]
- [[concepts/data-onboarding-orchestration-pipeline]]
- [[concepts/data-tokenization-and-encryption]]
- [[synthesis/data-acquisition-architecture-overview]]

## Sources

- External: Mar 11 _Data-Acquisition-Service-LLD-NarrativeV1.0[63].pdf
