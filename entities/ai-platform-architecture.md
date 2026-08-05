---
title: OCBC AI Platform Architecture
category: entities
tags: [aws, ai-platform, ocbc, ai-factory]
aliases: [AI Factory, AI Lab Suite]
relationships:
  - target: "[[entities/cloud-data-acquisition-service]]"
    type: related_to
sources: ["External: Overall AI Platform Arch.png"]
summary: OCBC's overall AWS AI platform — AI Factory shared-services account, per-environment AI Lab Suites, and an AI Control Tower for governance.
provenance:
  extracted: 0.55
  inferred: 0.45
  ambiguous: 0.0
base_confidence: 0.45
lifecycle: draft
lifecycle_changed: 2026-07-27
tier: supporting
created: 2026-07-27
updated: 2026-07-27
---

# OCBC AI Platform Architecture

The "Overall AI Platform Architecture" diagram lays out OCBC's target AWS account structure for AI/ML workloads, downstream of the [[entities/cloud-data-acquisition-service]]. Content below is read directly off the diagram; interpretation of box relationships is marked `^[inferred]` since a diagram was decoded rather than narrative text.

## Account Structure ^[inferred]

- **Cloud-Data-Acquisition-Account (Prod / Non-Prod)** — receives on-prem data via AWS DataSync, lands it in a SageMaker Lakehouse Catalog / Gold Zone.
- **AI-Factory-SS-Account (Artefact Account)** — shared services: Bedrock Evals (with a "Trusty AI" evaluation framework), Red Hat Keycloak, bias & explainability tooling, model monitor, container registry, Feast feature store, MLflow (experiment tracking + model registry), EventBridge, and a human-approval step gating promotion.
- **OCBC AI-Non-Production-Account** — contains two "AI Lab Suite" environments: one for experimentation (notebooks, VSCode IDE, Red Hat AI Workspace/AI Studio, Bedrock Guardrails, Airflow ML pipeline for EDA/Data Prep/Model Train/Model Evaluate) and one for serving (SageMaker endpoints, Bedrock LLMs, GPU serving infrastructure, RAG agents, batch processing applications).
- **OCBC AI-Production-Account** — mirrors the non-prod serving AI Lab Suite for production inference.
- **AI-Control-Tower-Account** — central governance: AI Lab Suite control plane, AI Factory control planes (prod/non-prod), observability (CloudWatch), CI/CD, SecOps, FinOps, and an Integration Hub (Data, MCP, Catalogs).
- **Red Hat AWS Account** — hosts a ROSA (Red Hat OpenShift Service on AWS) control plane and container registry.

## Relationship to Data Acquisition

The on-prem [[entities/cloud-data-acquisition-service]] (highlighted in the source diagram as "OCBC Corporate data center") feeds the Cloud-Data-Acquisition-Account, which in turn supplies curated/gold data to the AI Lab Suites for model training and serving. ^[inferred]

## Related

- [[entities/cloud-data-acquisition-service]]
- [[synthesis/data-acquisition-architecture-overview]]

## Sources

- External: Overall AI Platform Arch.png
