# Story 3.1: Scaffold Module and Environment Structure

Status: done

## Story

As a platform engineer,
I want the repository structured into `infra/modules/` and `infra/envs/<env>/`,
so that modules stay reusable and each environment has its own backend configuration.

## Acceptance Criteria

1. **Given** the architecture decision tree **when** this story completes **then** `infra/modules/` contains folders for `foundation-network`, `ack-cluster`, and `addons/{ingress-nginx,externaldns,cert-manager,argocd-bootstrap}` each with README + placeholder files. [Source: docs/epics.md#Epic-3-Terraform-Modules--ACK-Enablement]
2. **Given** the architecture decision tree **when** this story completes **then** `infra/envs/dev/` and `infra/envs/prod/` contain `main.tf`, `variables.tf`, `backend.tf`, `backend.hcl.example`, and `dev.tfvars.example` wired to module sources and remote-state outputs. [Source: docs/epics.md#Epic-3-Terraform-Modules--ACK-Enablement]

## Tasks / Subtasks

- [x] Create module scaffolding under `infra/modules/` (AC: 1)
  - [x] Add `infra/modules/foundation-network/` with `main.tf`, `variables.tf`, `outputs.tf`, `README.md` placeholders
  - [x] Add `infra/modules/ack-cluster/` with `main.tf`, `variables.tf`, `outputs.tf`, `README.md` placeholders
  - [x] Add `infra/modules/addons/ingress-nginx/` with `main.tf`, `variables.tf`, `outputs.tf`, `README.md` placeholders
  - [x] Add `infra/modules/addons/externaldns/` with `main.tf`, `variables.tf`, `outputs.tf`, `README.md` placeholders
  - [x] Add `infra/modules/addons/cert-manager/` with `main.tf`, `variables.tf`, `outputs.tf`, `README.md` placeholders
  - [x] Add `infra/modules/addons/argocd-bootstrap/` with `main.tf`, `variables.tf`, `outputs.tf`, `README.md` placeholders
- [x] Create environment scaffolding under `infra/envs/` (AC: 2)
  - [x] Extend `infra/envs/dev/` and `infra/envs/prod/` with missing files only: `main.tf`, `variables.tf`, `dev.tfvars.example`
  - [x] Keep existing backend files as-is; use `infra/envs/<env>/backend.hcl.example` as the source of truth for required keys
  - [x] Wire `main.tf` to use module sources (`../modules/...`) and reference remote-state outputs placeholders (region, bucket, key, profile, tablestore_table, tablestore_endpoint) from Epic 1 outputs
  - [x] Set `backend.tf` with `terraform { backend "oss" {} }` and keep config in `backend.hcl.example`
  - [x] Add `infra/envs/<env>/values/` with a minimal `README.md` placeholder for addon Helm values
  - [x] Optional (non-AC): add `prod.tfvars.example` for symmetry if desired
- [x] Align scaffolding with architecture conventions (AC: 1, 2)
  - [x] Use snake_case variable names and kebab-case folders
  - [x] Avoid inline resources in env `main.tf` (envs should only wire modules and locals)

## Dev Notes

- **Dependencies:** CloudSSO profile and remote-state bootstrap from Epic 1 are prerequisites; backends must reference OSS + TableStore outputs (bucket name, region, OTS endpoint, lock table). [Source: docs/architecture.md#Project-Initialization]
- **Module expectations:** Each module should include `variables.tf`, `outputs.tf`, and `README.md` even if empty placeholders; keep placeholders minimal and document TODOs. [Source: docs/architecture.md#Code-Organization]
- **Env wiring:** `infra/envs/<env>/main.tf` should only instantiate modules and pass variables (no raw resources). [Source: docs/architecture.md#Code-Organization]
- **Naming conventions:** Terraform variables are snake_case; folders are kebab-case; keep namespace prefixes consistent (e.g., `foundation-network`). [Source: docs/architecture.md#Naming-Conventions]
- **Do not modify:** `infra/envs/dev/backend.hcl`, `infra/envs/dev/.terraform/`, `infra/envs/*/backend.tf`, `infra/envs/*/backend.hcl.example`, or `infra/envs/*/REMOTE_STATE.md` (extend-only to avoid breaking backend init).

### Project Structure Notes

- Follow the exact repo layout described in `docs/architecture.md` (modules under `infra/modules`, environment stacks under `infra/envs`).
- No CI changes in this story; pipelines are addressed in Epic 4.

### References

- [Source: docs/epics.md#Epic-3-Terraform-Modules--ACK-Enablement]
- [Source: docs/architecture.md#Project-Structure]
- [Source: docs/architecture.md#Code-Organization]
- [Source: docs/architecture.md#Naming-Conventions]
- [Source: docs/architecture.md#Project-Initialization]

## Dev Agent Record

### Context Reference

<!-- Path(s) to story context XML will be added here by context workflow -->

### Agent Model Used

GPT-5 (Codex CLI)

### Debug Log References

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created
- Added module/env scaffolding placeholders and wired env stacks to module sources plus remote-state placeholders.
- Tests: `python3 tests/scaffold_structure_test.py`, `python3 tests/remote_state_test.py`.
- Review fixes: wired env modules to locals for remote-state placeholders and removed bootstrap remote_state data source to avoid backend mismatch.
- Note: Unrelated uncommitted files exist in the repo; excluded from this story's File List.

### File List

- docs/sprint-artifacts/3-1-scaffold-module-and-environment-structure.md
- docs/sprint-artifacts/sprint-status.yaml
- infra/envs/dev/dev.tfvars.example
- infra/envs/dev/main.tf
- infra/envs/dev/variables.tf
- infra/envs/dev/values/README.md
- infra/envs/prod/dev.tfvars.example
- infra/envs/prod/main.tf
- infra/envs/prod/prod.tfvars.example
- infra/envs/prod/variables.tf
- infra/envs/prod/values/README.md
- infra/modules/ack-cluster/README.md
- infra/modules/ack-cluster/main.tf
- infra/modules/ack-cluster/outputs.tf
- infra/modules/ack-cluster/variables.tf
- infra/modules/addons/argocd-bootstrap/README.md
- infra/modules/addons/argocd-bootstrap/main.tf
- infra/modules/addons/argocd-bootstrap/outputs.tf
- infra/modules/addons/argocd-bootstrap/variables.tf
- infra/modules/addons/cert-manager/README.md
- infra/modules/addons/cert-manager/main.tf
- infra/modules/addons/cert-manager/outputs.tf
- infra/modules/addons/cert-manager/variables.tf
- infra/modules/addons/externaldns/README.md
- infra/modules/addons/externaldns/main.tf
- infra/modules/addons/externaldns/outputs.tf
- infra/modules/addons/externaldns/variables.tf
- infra/modules/addons/ingress-nginx/README.md
- infra/modules/addons/ingress-nginx/main.tf
- infra/modules/addons/ingress-nginx/outputs.tf
- infra/modules/addons/ingress-nginx/variables.tf
- infra/modules/foundation-network/README.md
- infra/modules/foundation-network/main.tf
- infra/modules/foundation-network/outputs.tf
- infra/modules/foundation-network/variables.tf
- tests/scaffold_structure_test.py

### Change Log

- 2025-12-30: Added Terraform module and environment scaffolding with placeholders and structure tests.
- 2025-12-30: Review fixes for env wiring and scaffold test coverage.
