# ali-infrastructure

AliCloud-native Infrastructure as Code that provisions foundation networking, ACK (Alibaba Cloud Kubernetes) clusters, and core add-ons with Terraform. It standardizes remote state, identity, and pipelines, then hands off to GitOps (ArgoCD) for app delivery. Architecture and PRD live under `docs/`.

- Architecture overview: `docs/architecture.md:1`
- PRD and success criteria: `docs/prd.md:1`
- Epic/story breakdown: `docs/epics.md:1`

## Highlights
- Remote state bootstrap: OSS for state + TableStore for locking
- Layered Terraform modules with per-environment stacks
- Add-ons via Helm: ingress-nginx, ExternalDNS, cert-manager, ArgoCD bootstrap
- CloudSSO for humans; OIDC→RAM for CI; ACK workload identity ready
- GitOps handoff: ArgoCD “app of apps” ready via module
- Documentation/compliance hooks outlined in docs (plan/apply artifacts, diagrams)

## Repository Structure
```
infra/
  bootstrap/remote-state/     # One-time OSS + TableStore bootstrap
  modules/                    # Reusable Terraform modules
    foundation-network/       # VPC, subnets, NAT, SG
    ack-cluster/              # Managed ACK cluster + RRSA
    addons/
      ingress-nginx/
      externaldns/
      cert-manager/
      argocd-bootstrap/
  envs/
    dev/                      # Environment stack + values
    prod/

docs/                         # PRD, architecture, guidelines, sprint artifacts
scripts/                      # Helper scripts (auth, validation)
```

Key references:
- Remote state bootstrap: `infra/bootstrap/remote-state/README.md:1`
- Environment wiring: `infra/envs/README.md:1`
- Foundation network module: `infra/modules/foundation-network/README.md:1`
- ACK cluster module: `infra/modules/ack-cluster/README.md:1`
- Add-ons modules: ingress, externaldns, cert-manager, argocd-bootstrap READMEs under `infra/modules/addons/*/README.md:1`

## Prerequisites
- Terraform CLI 1.3+ (recommend 1.6.x)
- Aliyun CLI 3.0.271+
- CloudSSO access configured for your account
- Optional: SOPS + age if you manage encrypted values

## Quick Start

1) Authenticate via CloudSSO
- Follow `docs/guideline/boostrap-1-cloudsso.md:1`
- Validate: `aliyun sts GetCallerIdentity --profile SSOProfile`

2) Bootstrap remote state (once per tenant/environment set)
```bash
cd infra/bootstrap/remote-state
terraform init
cp terraform.tfvars.example terraform.tfvars   # if you maintain an example
# or fill required values per README
terraform apply -var-file=terraform.tfvars
```
Outputs include the OSS bucket, TableStore instance/table, and endpoint; you’ll use these in environment backends. See `infra/bootstrap/remote-state/README.md:1`.

3) Configure environment backend
- Copy `infra/envs/<env>/backend.hcl.example` to `backend.hcl`
- Populate values from step 2 outputs (bucket, key, region, TableStore endpoint/table)
```bash
cd infra/envs/dev
terraform init -backend-config=backend.hcl -migrate-state
```
See `infra/envs/README.md:1` for notes.

4) Plan and apply the DEV stack
- Review `infra/envs/dev/main.tf:1` and `infra/envs/dev/variables.tf:1`
- Copy `dev.tfvars.example` to `dev.tfvars` and adjust
```bash
cd infra/envs/dev
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

This provisions foundation networking, an ACK cluster, and selected add-ons (values under `infra/envs/dev/values/:1`).

## Modules Overview

- `foundation-network` — VPC, subnets, NAT, base SG
  - README: `infra/modules/foundation-network/README.md:1`
- `ack-cluster` — ACK cluster + node pool + RRSA; emits `kubeconfig` and `oidc_issuer_url`
  - README: `infra/modules/ack-cluster/README.md:1`
- `addons/ingress-nginx` — Ingress controller via Helm
  - README: `infra/modules/addons/ingress-nginx/README.md:1`
- `addons/externaldns` — DNS management via Helm
  - README: `infra/modules/addons/externaldns/README.md:1`
- `addons/cert-manager` — TLS automation via Helm
  - README: `infra/modules/addons/cert-manager/README.md:1`
- `addons/argocd-bootstrap` — ArgoCD installation and bootstrap hints
  - README: `infra/modules/addons/argocd-bootstrap/README.md:1`
- `alicloud-ecs-invoice-runner` — Optional ECS module for the invoice processing agent
  - README: `infra/alicloud-ecs-invoice-runner/README.md:1`
  - Tech spec: `docs/tech-spec-invoice-processing.md:1`

## GitOps Handoff
- The ArgoCD bootstrap module installs ArgoCD and sets up a starting point for GitOps. Point ArgoCD at your application repo(s) to continue delivery post-infra. See `infra/modules/addons/argocd-bootstrap/README.md:1`.

## CI/CD (Planned/Described in Docs)
- Standard workflows: fmt/tflint, validate/plan, DEV auto-apply, PROD gated apply, docs refresh
- Logs and summaries retained as artifacts; documentation updates pushed to `docs/`
- See `docs/architecture.md:1` and `docs/epics.md:1` for pipeline and compliance details

## Troubleshooting
- Backend init fails with credential errors: ensure your CloudSSO session is valid and the profile in `backend.hcl` matches your shell env. See `infra/envs/README.md:1`.
- ACK cluster attributes null right after create: allow a few minutes for API to populate, or use the module’s override inputs. See `infra/modules/ack-cluster/README.md:1`.
- Helm add-on installs fail: verify `kubeconfig_path` and per-env values files under `infra/envs/<env>/values/:1`.

## Contributing
- Keep modules self-contained with `variables.tf`, `outputs.tf`, and a README.
- Follow naming/organization guidance in `docs/architecture.md:1`.
- Update or add docs when behavior changes; sprint artifacts reside under `docs/sprint-artifacts/`.

## Related Docs
- Architecture: `docs/architecture.md:1`
- PRD: `docs/prd.md:1`
- Epics & stories: `docs/epics.md:1`
- CloudSSO bootstrap: `docs/guideline/boostrap-1-cloudsso.md:1`
- Remote state bootstrap: `docs/guideline/boostrap-2-remote-state.md:1`
- Terraform bootstrap guide: `docs/guideline/terraform-bootstrap.md:1`
