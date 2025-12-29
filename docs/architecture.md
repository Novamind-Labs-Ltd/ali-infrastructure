# Decision Architecture

## Executive Summary

Ali-infrastructure delivers an AliCloud-native IaC platform where every environment is provisioned through layered Terraform modules, GitHub Actions pipelines, and a GitOps handoff to ArgoCD. The architecture emphasizes an audited bootstrap flow—CloudSSO credentials feed a dedicated remote-state bootstrap module that stands up OSS + TableStore locking before any other stack runs—so DevOps agents can safely extend the system.

## Project Initialization

1. Authenticate via CloudSSO profile (`SSOProfile`) established in `bootstrap-1-cloudsso`.
2. Execute the remote-state bootstrap module under `infra/bootstrap/remote-state/` to create the OSS bucket and TableStore lock table, capturing outputs for region, bucket, OTS instance, and table name.
3. Configure each environment stack with `backend "oss" {}` and corresponding `backend.hcl` derived from bootstrap outputs, then run `terraform init -backend-config=backend.hcl -migrate-state`.
4. Commit the layered Terraform module skeleton (`infra/modules`, `infra/envs/<env>`) plus GitHub Actions workflows (`.github/workflows/terraform-plan.yml`, `terraform-apply.yml`) so agents have a consistent structure.

## Decision Summary

| Category | Decision | Version | Affects Epics | Rationale |
| -------- | -------- | ------- | ------------- | --------- |
| Remote State | Dedicated bootstrap module creates OSS bucket + OTS table using local state, then migrates stacks to the OSS backend | Terraform >= 1.3, AliCloud provider >=1.200 (verify latest) | E1 | Isolates critical dependency and aligns with `bootstrap-2-remote-state` guideline |
| Module Layout | `infra/modules` for reusable components and `infra/envs/<env>` for stacks with per-env backend config | N/A | E1,E2 | Enables DevOps agents to extend modules independently while keeping environments isolated |
| Identity & Secrets | CloudSSO for humans, GitHub Actions OIDC→RAM role for pipelines, ACK workload identity + SOPS for secrets | GitHub OIDC, AliCloud RAM (verify policy versions) | E1,E2,E3 | Meets FR11–FR13 and keeps credentials short-lived |
| Pipeline Orchestration | GitHub Actions stages: fmt/tflint, validate+plan, DEV auto-apply, PROD gated apply, documentation refresh job | Terraform CLI >=1.3, tfsec/tflint latest (verify) | E1,E3 | Provides audit trail and automation coverage requirements |
| GitOps Handoff | Terraform installs Helm add-ons (NGINX, ExternalDNS, Cert-Manager) then bootstraps ArgoCD with repo pointers | Helm 3.x, ArgoCD latest stable (verify) | E2 | Guarantees ACK clusters are immediately ready for services |
| Documentation Automation | Apply job commits regenerated docs/diagrams under `docs/` and posts links in pipeline summary | mkdocs/mermaid CLI of choice (verify) | E3 | Ensures 100% documentation freshness and compliance evidence |
| Compliance Logging | All plan/apply logs archived as artifacts and notified to compliance reviewers (Chen) via chat/webhook | GitHub Actions artifacts, chosen webhook | E3 | Provides traceability requirements (FR15–FR17) |

## Project Structure

```
repo-root/
├── infra/
│   ├── bootstrap/
│   │   └── remote-state/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── terraform.tfvars.example
│   ├── modules/
│   │   ├── foundation-network/
│   │   ├── ack-cluster/
│   │   └── addons/
│   │       ├── ingress-nginx/
│   │       ├── externaldns/
│   │       ├── cert-manager/
│   │       └── argocd-bootstrap/
│   └── envs/
│       ├── dev/
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   ├── backend.tf
│       │   └── backend.hcl.example
│       └── prod/
│           └── ... (mirrors dev)
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml
│       └── terraform-apply.yml
├── docs/
│   ├── analysis/
│   ├── guideline/
│   ├── architecture.md
│   └── ...
└── scripts/
    └── post-apply-docs/
```

## Epic to Architecture Mapping

| Epic / Journey | Architectural Elements |
| -------------- | ---------------------- |
| E1 – Terraform + Pipeline Backbone (Li Wei) | `infra/bootstrap/remote-state`, foundation-network & ack modules, GitHub Actions workflows |
| E2 – ACK Services & GitOps Handoff (Priya) | addons modules (NGINX, ExternalDNS, Cert-Manager, ArgoCD), ArgoCD repo bootstrap, workload identity setup |
| E3 – Compliance & Documentation Transparency (Chen) | Pipeline artifact retention, documentation automation scripts, OSS/TableStore audit data |

## Technology Stack Details

### Core Technologies
- Terraform CLI >= 1.3 (recommend 1.6.x; verify latest before execution).
- AliCloud Terraform provider >= 1.200 for OSS/OTS support.
- Helm 3.x for cluster add-ons.
- ArgoCD (latest stable) for GitOps handoff.
- GitHub Actions for CI/CD, including OIDC federation to AliCloud RAM roles.
- SOPS (age backend) for encrypting environment-specific configuration.
- aliyun CLI for CloudSSO profile refresh.

### Integration Points
- GitHub Actions → AliCloud RAM role via OIDC trust; role assumes permissions limited to Terraform resources.
- Terraform `addon` modules → Helm releases installed into ACK after control plane is provisioned.
- Post-apply docs script writes Markdown + Mermaid diagrams back into `docs/` and pushes changes (or opens PR).
- Compliance notification hook posts plan/apply artifact links to team's chat or ticketing system.

## Implementation Patterns

- Terraform resources use snake_case logical names and prefix with module purpose (e.g., `network_vpc`, `ack_nodes`).
- OSS buckets use kebab-case (`ali-infra-tfstate-<region>`), lock tables use snake_case (`terraform_state_lock`).
- GitHub workflows named `terraform-plan` and `terraform-apply`; environment-specific jobs reference `env` input.
- Helm charts stored in `infra/modules/addons/*` with values files per environment under `infra/envs/<env>/values/`.
- Documentation automation script always runs after successful apply and regenerates diagrams using deterministic filenames.

## Consistency Rules

### Naming Conventions
- Terraform variables: snake_case (`remote_state_bucket`).
- File/folder names: kebab-case for directories except Terraform defaults.
- Kubernetes namespaces: `ali-infra-system`, `ali-infra-gitops`.
- GitHub Actions environment names: `dev`, `prod` (lowercase).

### Code Organization
- Each Terraform module exposes `variables.tf`, `outputs.tf`, and README.
- Environment stacks import modules only via versioned `source = "../modules/<name>"` paths; no inline resources allowed in env-level `main.tf` except wiring and locals.
- Tests (terraform validate/tflint) live inside CI workflows, not separate folders.

### Error Handling
- CI pipeline fails fast on fmt/tflint validation; plan step uploads artifacts even on failure.
- Terraform apply uses `-lock-timeout=5m`; retries documented in runbook.
- GitHub Actions notifies on lock contention pointing to TableStore key for manual unlock.

### Logging Strategy
- GitHub Actions logs retained 90 days; plan/apply summaries exported as Markdown artifacts.
- ArgoCD app-of-apps structure logs sync status; linked in documentation updates.
- Terraform state bucket has versioning enabled so drift can be audited.

## Data Architecture

- Terraform state stored in OSS bucket with versioning + SSE AES256.
- Lock data stored in TableStore table keyed by `LockID` string.
- Documentation outputs stored in Git repo (`docs/`) with history capturing each apply.
- Compliance metadata (plan/apply logs) archived as GitHub artifacts and optionally mirrored to OSS for long-term retention.

## API Contracts

- GitHub Actions summary comment includes JSON payload: `{ "plan_url": "...", "apply_url": "...", "docs_diff": "..." }` consumed by notification hooks.
- ArgoCD bootstrap expects repo URL + path values; documented in `infra/modules/addons/argocd-bootstrap/README.md`.
- Documentation automation script exposes `POST /docs-update` webhook (optional) to notify Confluence or other portals.

## Security Architecture

- CloudSSO profile renewed before each local apply; no static access keys committed.
- GitHub Actions uses OIDC trust relationship with scoped RAM policy limited to Terraform-managed resources.
- ACK cluster configured with OIDC provider so workloads can assume RAM roles via ServiceAccount annotations.
- SOPS-encrypted files stored in repo with `.sops.yaml` enforcing age recipients; decrypted only within CI jobs or developers’ machines with proper keys.

## Performance Considerations

- Pipelines target < 1 hour end-to-end; lint/plan steps run in parallel to shorten feedback loops.
- Terraform modules enforce minimal diff strategy (split modules to avoid unnecessary resource recreation).
- OSS bucket lifecycle policies keep older state versions but expire after 180 days to control costs.

## Deployment Architecture

- Terraform executes from GitHub Actions runners; remote state and locking reside in AliCloud.
- ACK cluster hosts add-ons plus ArgoCD; ArgoCD syncs application repos hosted on GitHub.
- Documentation automation job runs as final pipeline step and pushes artifacts back to repo.

## Development Environment

### Prerequisites
- Terraform >= 1.6.x
- aliyun CLI configured with CloudSSO profile
- Direnv or `aws-vault` alternative for environment variables
- SOPS + age keypair

### Setup Commands

```bash
aliyun configure --profile SSOProfile --mode CloudSSO
cd infra/bootstrap/remote-state
terraform init
terraform apply -var="bucket_name=<unique>"
cd ../../envs/dev
terraform init -backend-config=backend.hcl
terraform plan -var-file=dev.tfvars
```

## Architecture Decision Records (ADRs)

1. **ADR-001 Remote State Bootstrap** – Use dedicated bootstrap module to provision OSS + TableStore before switching other stacks to the oss backend.
2. **ADR-002 Layered Module Layout** – Place reusable modules under `infra/modules` with environment overlays under `infra/envs/<env>` to isolate concerns.
3. **ADR-003 Identity & Secrets Flow** – CloudSSO for humans, GitHub OIDC for pipelines, ACK workload identity + SOPS for runtime secrets.
4. **ADR-004 Pipeline Orchestration** – Standardize GitHub Actions workflows for fmt/tflint, plan, apply, documentation updates, and compliance notifications.
5. **ADR-005 GitOps Handoff** – Terraform installs required Helm add-ons and bootstraps ArgoCD to delegate service deployments.
6. **ADR-006 Documentation & Compliance Automation** – Each apply refreshes docs/diagrams, publishes artifacts, and notifies compliance stakeholders.

---

_Generated by BMAD Decision Architecture Workflow v1.0_
_Date: 2025-12-24_
_For: kk_
