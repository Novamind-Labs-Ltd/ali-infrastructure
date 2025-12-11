---
stepsCompleted: [1, 2, 3, 4, 5]
inputDocuments:
  - docs/analysis/brainstorming-session-2025-12-10.md
workflowType: 'product-brief'
lastStep: 5
project_name: 'ali-infrastructure'
user_name: 'kk'
date: '2025-12-11'
---

# Product Brief: ali-infrastructure

**Date:** 2025-12-11
**Author:** kk

---

<!-- Content will be appended sequentially through collaborative workflow steps -->
## Executive Summary

Ali-Infrastructure is a greenfield initiative to codify AliCloud infrastructure and ACK-based microservices deployment through Terraform-driven automation and transparent pipelines. Teams currently lack repeatable patterns and documentation for AliCloud, which forces manual console setup and risky drift. By establishing an IaC-first platform, dedicated GitHub Actions pipelines, and GitOps handoffs (ArgoCD), we reduce manual effort, ensure service transparency, and give stakeholders confidence in every deployed resource. Success means developers and infra engineers can provision AliCloud resources and microservices as easily as they would on AWS or Azure—without hidden manual steps.

---

## Core Vision

### Problem Statement

Organizations need a maintainable, auditable way to deploy AliCloud infrastructure and microservices, but today there are almost no reusable patterns or documented pipelines for ACK. Teams either copy AWS/Azure practices that don’t translate well or resort to manual console operations, leading to drift and fragile environments.

### Problem Impact

- High manual effort to provision or patch AliCloud resources because every project starts from scratch.
- No shared pipeline patterns; deployments vary per engineer, causing inconsistent security and compliance posture.
- Lack of transparency: stakeholders can’t easily see how resources were created or how services flow through environments.

### Why Existing Solutions Fall Short

- Community examples focus on AWS/Azure; AliCloud-specific tooling is sparse.
- Native AliCloud consoles offer ad-hoc provisioning but no repeatability or source control.
- Some teams script resources piecemeal, but without a pipeline they still rely on manual applies and limited visibility.

### Proposed Solution

Build a Terraform-based AliCloud platform that provisions core networking, ACK clusters, and required add-ons (NGINX, ExternalDNS, Cert-Manager). Pair it with GitHub Actions for lint/plan/apply, plus GitOps (ArgoCD) to deliver workloads. Every apply updates documentation and diagrams so the platform remains transparent. The result is a self-serve, IaC-first environment where microservices land on AliCloud with the same ease as other clouds.

### Key Differentiators

- Terraform modules designed specifically for AliCloud + ACK, not generic multi-cloud scripts.
- End-to-end automation: GitHub Actions handles IaC promotion, ArgoCD handles workloads, with identity managed via OIDC and SOPS.
- Documentation hooks ensure every change updates architecture diagrams and runbooks, keeping stakeholders aligned.

## Target Users

### Primary Users

**Cloud Platform Engineers (AliCloud Specialists)**
- Responsible for provisioning and maintaining infrastructure across environments.
- Today they rely on manual console work or ad-hoc scripts, with little AliCloud-specific guidance.
- They want Terraform modules and pipelines that give predictable, auditable outcomes.

**DevOps / Site Reliability Engineers**
- Own CI/CD and runtime reliability for microservices that now need ACK support.
- Current pipelines are inconsistent, secrets management is manual, and GitOps isn’t standardized.
- They want an IaC + GitOps backbone where Terraform handles infra and ArgoCD takes over workloads automatically.

### Secondary Users

**Security / Compliance Stakeholders**
- Need proof that infrastructure changes are reviewed, documented, and traceable.
- Benefit from automated documentation updates, OIDC-based identity, and SOPS-encrypted secrets.

### User Journey

1. **Discovery:** Platform engineers and DevOps realize AliCloud deployments are emerging but lack tooling parity with AWS/Azure.
2. **Onboarding:** They clone the Terraform modules, configure GitHub Actions for dev/test/prod, and bootstrap ACK with Helm add-ons.
3. **Core Usage:** Engineers submit PRs, run fmt/lint/plan automatically, and merge to trigger dev applies. Release tags gate production applies; ArgoCD deploys workloads.
4. **Success Moment:** ACK cluster is up with NGINX/ExternalDNS/Cert-Manager configured; documentation auto-updates and microservices deploy seamlessly.
5. **Long-term:** Teams adopt the pipeline as the canonical path for AliCloud; manual work drops, and compliance teams trust the automated audit trail.

## Success Metrics

**User Outcomes**
- Environments (networking + ACK + add-ons) provisioned end-to-end via Terraform/GitHub Actions in under 1 hour.
- ≥ 90% of infrastructure changes flow through the standardized pipeline (tracked via commits vs. manual operations).
- New services onboard onto ACK with zero manual console steps—only Git commits and pipeline approvals.

### Business Objectives

- Reduce manual deployment effort by 70% within 6 months (measure hours saved per environment).
- Double the number of microservices running on AliCloud within 12 months.
- Achieve 100% documentation freshness: every apply updates diagrams/runbooks automatically.

### Key Performance Indicators

- **Provisioning Lead Time:** Average hours from merge to fully deployed ACK environment.
- **Adoption Rate:** Number of AliCloud-backed services per quarter.
- **Automation Coverage:** % of infrastructure changes executed via pipelines vs. manual.
- **Documentation Freshness Index:** % of pipeline runs that successfully refresh docs/diagrams.

## MVP Scope

### Core Features

- Terraform modules that provision ACK (including networking prerequisites) plus required add-ons (NGINX ingress, ExternalDNS, Cert-Manager).
- GitHub Actions pipeline that runs terraform fmt/tflint/validate/plan on PRs and apply on merge with environment separation (DEV auto apply, manual prod gate).
- Automated documentation hooks so applies capture outputs and update docs even if ArgoCD is manual for now.

### Out of Scope for MVP

- ArgoCD automation (will be installed manually post-MVP).
- Production workload deployments (focus on DEV environment with a test pod).
- Advanced observability/reporting (centralized logging, metrics dashboards).

### MVP Success Criteria

- DEV ACK cluster deployed via Terraform pipeline within 2 weeks, with a test pod running successfully.
- Pipeline executes plan/apply end-to-end without manual intervention for DEV.
- Documentation updates occur as part of the pipeline run.

### Future Vision

- Deploy ArgoCD (or equivalent GitOps) to manage microservices automatically.
- Extend to multiple environments (Test/Prod) with formal release gates and approvals.
- Layer on observability, compliance automation, and potentially multi-region support once core automation is stable.
