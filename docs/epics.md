stepsCompleted:
- 1
- 2
- 3
- 4
inputDocuments:
  - docs/prd.md
  - docs/architecture.md
  - docs/guideline/boostrap-1-cloudsso.md
  - docs/guideline/boostrap-2-remote-state.md
  - docs/guideline/terraform-bootstrap.md
---

# ali-infrastructure - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for ali-infrastructure, decomposing the requirements from the PRD, UX Design if it exists, and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

FR1: Cloud platform engineers can provision AliCloud networking, ACK clusters, and required add-ons via standardized Terraform modules.
FR2: Platform engineers can trigger GitHub Actions workflows that run fmt/tflint/validate/plan/apply for each Terraform change.
FR3: Pipelines can separate DEV vs Prod behavior (auto-apply vs manual gate) while logging every run for audit.
FR4: Pipelines can update documentation artifacts (Markdown + diagrams) after each apply so the state of infrastructure is transparent.
FR5: DevOps/SREs can retrieve ACK endpoints, credentials, and bootstrap instructions produced by the pipeline to onboard services.
FR6: DevOps/SREs can deploy microservices to ACK using ArgoCD (manual for MVP, automated post-MVP) with clear handoff points from infrastructure pipeline.
FR7: DevOps/SREs can verify post-provision test pods or health checks to ensure clusters are ready for applications.
FR8: Stakeholders can view automatically generated documentation summarizing resources, diagrams, and change history for each apply.
FR9: Compliance reviewers can access plan/apply logs, diff summaries, and documentation updates from a single workspace.
FR10: Each Terraform module includes a README with usage examples, input/output tables, and reference diagrams.
FR11: Pipelines can assume AliCloud RAM roles via OIDC to run Terraform without storing static credentials.
FR12: ACK workloads can assume RAM roles via workload identity to access AliCloud services securely.
FR13: SOPS-encrypted configuration files can be stored in repo and decrypted only within authorized pipelines or pods.
FR14: Remote state is stored per-environment in OSS with Table Store locking so teams cannot corrupt each other’s state.
FR15: Compliance reviewers can subscribe to notifications that link to pipeline runs and documentation diffs for auditing.
FR16: Team members can trace any deployed resource back to the corresponding commit, plan/apply run, and documentation snapshot.
FR17: Platform owners can generate reports showing automation coverage vs manual changes.
FR18: Platform admins can publish module versions to the Terraform registry and deprecate old versions when needed.
FR19: Platform admins can configure environment-specific variables (state bucket names, region, etc.) without modifying module code.
FR20: Platform admins can onboard new teams by giving them access to the registry, pipelines, and documentation templates.

### NonFunctional Requirements

NFR-P1: No explicit performance targets for MVP; pipelines may run asynchronously, with future timing SLAs defined once usage patterns emerge.
NFR-S1: Terraform pipelines assume AliCloud RAM roles via OIDC; no long-lived credentials may be stored in repo or GitHub Actions secrets.
NFR-S2: SOPS-encrypted secrets must remain encrypted at rest and only be decrypted within authorized pipelines or ACK pods.
NFR-SC1: MVP supports a single team with sequential pipelines; roadmap must plan for 10+ concurrent pipelines triggered by AI agents or developers without interfering with OSS/TableStore state.
NFR-R1: Pipelines can retry failed Terraform operations manually; no strict uptime guarantee for MVP, with reliability targets defined after initial usage.
NFR-I1: Terraform registry (or artifact storage) must provide versioned modules accessible via authenticated requests; pipelines should gracefully handle temporary registry outages.
NFR-I2: GitHub Actions must integrate with AliCloud APIs via OIDC without manual credential refresh.

### Additional Requirements

- CloudSSO profile (bootstrap-1) is already configured; all local CLI operations must use this profile and re-auth on expiry.
- Remote-state bootstrap (bootstrap-2) must create an OSS bucket with versioning + SSE encryption plus a dedicated TableStore instance and lock table before any other Terraform stack runs.
- Terraform project must include `infra/bootstrap/remote-state/`, `infra/modules/`, and `infra/envs/<env>/` structure to separate reusable modules from environment wiring.
- Each environment stack must declare `backend "oss"` and load backend configuration from environment-specific `backend.hcl` files referencing bootstrap outputs.
- GitHub Actions pipelines must include fmt/tflint, validate/plan, DEV auto-apply, and PROD gated apply stages with documentation refresh steps.
- Pipelines must publish plan/apply logs as artifacts and notify compliance reviewers (Chen) with links.
- Terraform modules must provision AliCloud networking, ACK clusters, and Helm add-ons (NGINX ingress, ExternalDNS, Cert-Manager) plus bootstrap ArgoCD for GitOps handoff.
- Identity model must cover CloudSSO for humans, GitHub Actions OIDC → RAM role, ACK workload identity for pods, and SOPS-encrypted configuration files.
- Documentation automation scripts must regenerate Markdown + diagrams within `docs/` after every apply and reference pipeline runs.
- Compliance controls must ensure Terraform state bucket versioning, TableStore locking, and audit-ready artifact storage for each change.

### FR Coverage Map

FR1: Epic 3 – Terraform Modules & ACK Enablement
FR2: Epic 4 – Pipeline Automation & GitOps Promotion
FR3: Epic 4 – Pipeline Automation & GitOps Promotion
FR4: Epic 4 – Pipeline Automation & GitOps Promotion
FR5: Epic 3 – Terraform Modules & ACK Enablement
FR6: Epic 3 – Terraform Modules & ACK Enablement
FR7: Epic 3 – Terraform Modules & ACK Enablement
FR8: Epic 5 – Documentation, Compliance & Adoption
FR9: Epic 5 – Documentation, Compliance & Adoption
FR10: Epic 3 – Terraform Modules & ACK Enablement
FR11: Epic 2 – Identity & Secrets Automation
FR12: Epic 2 – Identity & Secrets Automation
FR13: Epic 2 – Identity & Secrets Automation
FR14: Epic 1 – Remote State Bootstrap
FR15: Epic 5 – Documentation, Compliance & Adoption
FR16: Epic 5 – Documentation, Compliance & Adoption
FR17: Epic 5 – Documentation, Compliance & Adoption
FR18: Epic 3 – Terraform Modules & ACK Enablement
FR19: Epic 2 – Identity & Secrets Automation
FR20: Epic 5 – Documentation, Compliance & Adoption

## Epic List

### Epic 1: Remote State Bootstrap
Stand up the dedicated remote-state foundation (OSS bucket with versioning + SSE, TableStore instance and lock table, backend configs) so every Terraform stack has consistent storage and locking before any other epic proceeds.
**FRs covered:** FR14

### Epic 2: Identity & Secrets Automation
Implement CloudSSO-driven human access, GitHub Actions OIDC → RAM role federation, ACK workload identity, and SOPS-encrypted configuration management so all environments operate without static credentials.
**FRs covered:** FR11, FR12, FR13, FR19

### Epic 3: Terraform Modules & ACK Enablement
Ship reusable Terraform modules that provision AliCloud networking, ACK clusters, and Helm add-ons (NGINX, ExternalDNS, Cert-Manager, ArgoCD) with documented inputs/outputs so platform engineers and DevOps can build environments rapidly and publish modules to a registry.
**FRs covered:** FR1, FR5, FR6, FR7, FR10, FR18

### Epic 4: Pipeline Automation & GitOps Promotion
Implement GitHub Actions workflows that lint, plan, and apply Terraform across environments with DEV auto-apply and PROD gates, updating documentation hooks and ensuring pipeline artifacts link GitOps handoffs cleanly.
**FRs covered:** FR2, FR3, FR4

### Epic 5: Documentation, Compliance & Adoption
Provide the transparency layer: automated documentation refresh, compliance notifications, change tracing, adoption reporting, and onboarding assets so stakeholders (Li Wei, Priya, Chen, new teams) can trust and expand the platform.
**FRs covered:** FR8, FR9, FR15, FR16, FR17, FR20

## Epic 1: Remote State Bootstrap

Stand up the dedicated remote-state foundation (OSS bucket with versioning + SSE, TableStore instance and lock table, backend configs) so every Terraform stack has consistent storage and locking before any other epic proceeds.
**FRs covered:** FR14

### Story 1.1: Bootstrap Remote State Infrastructure

As a platform engineer,  
I want a Terraform bootstrap module that creates the OSS bucket and TableStore lock table using local state,  
So that every environment can safely migrate to the shared remote backend before other stacks run.

**Acceptance Criteria:**

**Given** I run Terraform from `infra/bootstrap/remote-state/` with my CloudSSO profile  
**When** I execute `terraform apply` with a unique bucket name and region  
**Then** it provisions an OSS bucket with private ACL, versioning enabled, and AES256 SSE  
**And** it provisions a TableStore instance plus a `terraform-state-lock` table with `LockID` string primary key

**Given** the bootstrap apply completes  
**When** I inspect Terraform outputs  
**Then** I see the bucket name, TableStore instance endpoint, and table name documented for consumption by environment stacks

### Story 1.2: Configure Environment Backends to Use Remote State

As a platform engineer,  
I want each environment stack to load backend configuration from the bootstrap outputs,  
So that Terraform init migrates state into the shared OSS bucket with TableStore locking.

**Acceptance Criteria:**

**Given** `infra/envs/dev/` and `infra/envs/prod/` exist  
**When** I open each folder  
**Then** I see `backend.tf` declaring `backend "oss" {}` and a `backend.hcl.example` referencing bucket, region, key, and TableStore endpoint placeholders

**Given** bootstrap outputs are available  
**When** I run `terraform init -backend-config=backend.hcl` in either environment  
**Then** the command migrates (or initializes) state into the OSS bucket and confirms TableStore locking is active

## Epic 2: Identity & Secrets Automation

Implement CloudSSO-driven human access, GitHub Actions OIDC → RAM role federation, ACK workload identity, and SOPS-encrypted configuration management so all environments operate without static credentials.
**FRs covered:** FR11, FR12, FR13, FR19

### Story 2.1: Configure GitHub Actions OIDC Trust for Terraform Pipelines

As a platform engineer,  
I want a RAM role and trust policy for GitHub Actions OIDC,  
So that CI pipelines can assume short-lived credentials without storing static keys.

**Acceptance Criteria:**

**Given** the ali-infrastructure GitHub repository  
**When** the identity Terraform stack applies  
**Then** it creates a RAM role scoped to Terraform resources and an OIDC trust policy limited to the repo/environment claims

**Given** I trigger the GitHub Actions plan workflow  
**When** it requests the RAM role using OIDC  
**Then** the run acquires temporary credentials and can call AliCloud APIs without stored access keys

### Story 2.2: Establish ACK Workload Identity and SOPS Secret Management

As a DevOps engineer,  
I want ACK clusters to issue RAM roles to pods and Terraform to manage SOPS-encrypted configs,  
So that workloads and pipelines access AliCloud services securely.

**Acceptance Criteria:**

**Given** the ACK cluster exists  
**When** Terraform applies the workload identity module  
**Then** it creates an OIDC provider for the cluster and example RAM roles bound to ServiceAccounts through annotations

**Given** `.sops.yaml` and age recipients are configured  
**When** I run `sops -d secrets.enc.yaml` locally or in CI  
**Then** the file decrypts successfully while remaining encrypted in git, and CI logs show decryption succeeded without exposing plaintext in history

## Epic 3: Terraform Modules & ACK Enablement

Ship reusable Terraform modules that provision AliCloud networking, ACK clusters, and Helm add-ons (NGINX, ExternalDNS, Cert-Manager, ArgoCD) with documented inputs/outputs so platform engineers and DevOps can build environments rapidly and publish modules to a registry.
**FRs covered:** FR1, FR5, FR6, FR7, FR10, FR18

### Story 3.1: Scaffold Module and Environment Structure

As a platform engineer,  
I want the repository structured into `infra/modules/` and `infra/envs/<env>/`,  
So that modules stay reusable and each environment has its own backend configuration.

**Acceptance Criteria:**

**Given** the architecture decision tree  
**When** this story completes  
**Then** `infra/modules/` contains folders for `foundation-network`, `ack-cluster`, and `addons/{ingress-nginx,externaldns,cert-manager,argocd-bootstrap}` each with README + placeholder files  
**And** `infra/envs/dev/` and `infra/envs/prod/` contain `main.tf`, `variables.tf`, `backend.tf`, `backend.hcl.example`, and `dev.tfvars.example` wired to module sources and remote-state outputs

### Story 3.2: Implement Foundation Network Module

As a platform engineer,  
I want a Terraform module that provisions the VPC, subnets, and security groups required for ACK,  
So that any environment stack can reuse consistent networking primitives.

**Acceptance Criteria:**

**Given** inputs for CIDR ranges, zones, and tags  
**When** I apply the `foundation-network` module  
**Then** it creates an AliCloud VPC, public/private subnets, NAT gateway, and security groups with outputs for IDs and resource names

**Given** module documentation requirements  
**When** the module is published  
**Then** its README lists inputs/outputs, example usage, and dependency notes

### Story 3.3: Deliver ACK Cluster Module with Helm Add-ons

As a platform engineer,  
I want the ACK module to create the control plane, node pools, and install Helm add-ons (NGINX, ExternalDNS, Cert-Manager, ArgoCD),  
So that DevOps teams can deploy workloads immediately after provision.

**Acceptance Criteria:**

**Given** network IDs and cluster sizing inputs  
**When** Terraform applies `ack-cluster`  
**Then** it provisions the ACK cluster, node pools, configures OIDC bindings, and executes Helm releases for each addon using environment values files

**Given** the module completes  
**When** I review outputs  
**Then** it exposes ACK endpoint, kubeconfig artifacts, addon status (ingress hostnames, DNS zones, certificate issuers), and ArgoCD bootstrap instructions

## Epic 4: Pipeline Automation & GitOps Promotion

Implement GitHub Actions workflows that lint, plan, and apply Terraform across environments with DEV auto-apply and PROD gates, updating documentation hooks and ensuring pipeline artifacts link GitOps handoffs cleanly.
**FRs covered:** FR2, FR3, FR4

### Story 4.1: Create Terraform Plan Workflow with fmt/tflint/validate

As a DevOps engineer,  
I want a GitHub Actions workflow that runs fmt, tflint, and terraform validate/plan on every pull request,  
So that infrastructure changes are linted and reviewed before merge.

**Acceptance Criteria:**

**Given** a pull request targeting `main`  
**When** the `terraform-plan` workflow runs  
**Then** it checks out the repo, runs `terraform fmt -check`, `tflint`, and `terraform plan` for the targeted environment, uploading the plan artifact and posting a summary comment with success/failure status

### Story 4.2: Implement Apply Workflow with DEV Auto-apply and PROD Approval

As a DevOps engineer,  
I want a workflow that applies Terraform automatically to DEV on merge and requires manual approval for PROD,  
So that environments stay consistent while protecting production.

**Acceptance Criteria:**

**Given** a merge to `main`  
**When** the `terraform-apply` workflow triggers  
**Then** it applies to DEV using the remote backend, regenerates documentation artifacts, and commits/pushes doc changes (or opens a PR)

**Given** a release tag or manual dispatch for PROD  
**When** the PROD job runs  
**Then** it pauses for approval, applies Terraform with `-lock-timeout=5m`, and posts apply logs plus documentation links in the workflow summary

## Epic 5: Documentation, Compliance & Adoption

Provide the transparency layer: automated documentation refresh, compliance notifications, change tracing, adoption reporting, and onboarding assets so stakeholders (Li Wei, Priya, Chen, new teams) can trust and expand the platform.
**FRs covered:** FR8, FR9, FR15, FR16, FR17, FR20

### Story 5.1: Automate Documentation Refresh After Apply

As a documentation stakeholder,  
I want each Terraform apply to regenerate Markdown and diagrams,  
So that docs stay in sync with deployed infrastructure.

**Acceptance Criteria:**

**Given** the apply workflow completes  
**When** the post-apply script runs  
**Then** it updates `docs/` with latest architecture snapshots, runbook sections, and references to the pipeline run, committing changes or opening a PR automatically

### Story 5.2: Notify Compliance Reviewers with Plan/Apply Artifacts

As a compliance reviewer,  
I want notifications containing plan/apply logs and documentation diffs,  
So that I can audit infrastructure changes quickly.

**Acceptance Criteria:**

**Given** plan or apply workflows finish  
**When** artifacts are uploaded  
**Then** the workflow sends a webhook or chat message containing artifact links, documentation diff link, commit SHA, environment, and operator for audit tracking
