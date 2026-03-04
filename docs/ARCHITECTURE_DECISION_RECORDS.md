# Architecture Decision Records (ADRs)

<!-- TOC -->
* [Architecture Decision Records (ADRs)](#architecture-decision-records-adrs)
  * [Introduction](#introduction)
  * [Records](#records)
<!-- TOC -->

## Introduction

Architecture Decision Records (ADRs) document important architectural decisions made during the development of this application. They provide context, rationale, and consequences for significant choices that shape the system's design and evolution.

## Records

| Title | Description | Decision |
|----------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------|----------|
| [ADR 0001: Use Binary Torch Packages for the Homelab Demucs Runtime](architecture_decision_records/0001-use-binary-torch-packages-for-homelab-demucs-runtime.md) | Use prebuilt Torch and Torchaudio packages for the non-core `homelab-demucs` runtime to avoid multi-hour source builds on target hosts | Pending |

When making significant architectural decisions for this application, create a new ADR in the `architecture_decision_records` directory to document the decision-making process and outcomes.
