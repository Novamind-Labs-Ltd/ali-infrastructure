# Story 3.2: Implement Foundation Network Module

Status: done

## Story

As a platform engineer,
I want a Terraform module that provisions the VPC, subnets, and security groups required for ACK,
so that any environment stack can reuse consistent networking primitives.

## Acceptance Criteria

1. **Given** inputs for CIDR ranges, zones, and tags **when** I apply the `foundation-network` module **then** it creates an AliCloud VPC, public/private subnets, NAT gateway, and security groups with outputs for IDs and resource names. [Source: docs/epics.md#Story-32-Implement-Foundation-Network-Module]
2. **Given** module documentation requirements **when** the module is published **then** its README lists inputs/outputs, example usage, and dependency notes. [Source: docs/epics.md#Story-32-Implement-Foundation-Network-Module]

## Tasks / Subtasks

- [x] Implement `infra/modules/foundation-network/` Terraform module (AC: 1)
  - [x] Add `main.tf` with AliCloud VPC, subnets (public/private), NAT gateway, and security groups
  - [x] Add `variables.tf` defining CIDR ranges, zones, and tagging inputs
  - [x] Add `outputs.tf` exporting VPC ID, subnet IDs, NAT gateway ID, and security group IDs
- [x] Provide module documentation (AC: 2)
  - [x] Update `infra/modules/foundation-network/README.md` with inputs/outputs tables, example usage, and dependency notes
- [x] Align with architecture conventions (AC: 1, 2)
  - [x] Use snake_case variable names and kebab-case directory names
  - [x] Keep module focused on reusable networking primitives (no environment-specific wiring)
- [x] Validate module quality before handoff (AC: 1)
  - [x] Run `terraform fmt` and `terraform validate` for the module directory
  - [x] Run `tflint` if configured for this repo

## Dev Notes

- **Epic context:** Epic 3 is about reusable Terraform modules that unlock ACK provisioning. This module is a prerequisite for the ACK cluster module and later environment wiring. [Source: docs/epics.md#Epic-3-Terraform-Modules--ACK-Enablement]
- **Architecture scope:** Modules live under `infra/modules/` and environment stacks wire them in `infra/envs/<env>/` without inline resources. [Source: docs/architecture.md#Project-Structure]
- **Module layout:** Each module must expose `variables.tf`, `outputs.tf`, and README with usage examples. [Source: docs/architecture.md#Code-Organization]
- **Naming conventions:** Terraform variables use snake_case; directories use kebab-case. [Source: docs/architecture.md#Naming-Conventions]
- **Remote state dependency:** Environment stacks consume remote state from the bootstrap module; do not add backend config here. [Source: docs/architecture.md#Project-Initialization]
- **Version expectations:** Terraform CLI >= 1.3 (recommend 1.6.x) and AliCloud provider >= 1.200; add a provider constraint in the module or document where version pinning lives. [Source: docs/architecture.md#Technology-Stack-Details]
- **Provider constraints:** Add a `required_providers` block with an explicit AliCloud version range (or reference the canonical pin file if the repo centralizes provider constraints). [Source: docs/architecture.md#Technology-Stack-Details]
- **Network inputs (minimum):** `vpc_cidr`, `public_subnet_cidrs`, `private_subnet_cidrs`, `zones`, `tags`, `name_prefix` (or equivalent). Keep variable names snake_case. [Source: docs/epics.md#Story-32-Implement-Foundation-Network-Module]
- **Expected outputs (minimum):** `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `nat_gateway_id`, `security_group_ids` (or equivalent). [Source: docs/epics.md#Story-32-Implement-Foundation-Network-Module]
- **Subnet/NAT strategy:** Define at least one public and one private subnet per zone; NAT should service private subnets. Keep counts driven by input lists. [Source: docs/epics.md#Story-32-Implement-Foundation-Network-Module]
- **Security groups:** Default to least-privilege rules; avoid wide-open ingress. If placeholders are required, document them clearly in README. [Source: docs/prd.md#Security]
- **Dependencies:** Requires Story 3.1 scaffolding to exist; outputs must be compatible with the upcoming ACK cluster module (Story 3.3). [Source: docs/epics.md#Epic-3-Terraform-Modules--ACK-Enablement]
- **Regression guardrail:** Avoid renaming outputs or changing their shape without coordinating with env wiring and the ACK module; preserve backward-compatible outputs where possible. [Source: docs/architecture.md#Code-Organization]

### Project Structure Notes

- If `infra/modules/` is not present yet, create it following Story 3.1 scaffolding; do not introduce new layout variations. [Source: docs/architecture.md#Project-Structure]
- Avoid adding environment-specific values or Helm charts in this module; those belong in later stories. [Source: docs/architecture.md#Implementation-Patterns]

### References

- [Source: docs/epics.md#Story-32-Implement-Foundation-Network-Module]
- [Source: docs/architecture.md#Project-Structure]
- [Source: docs/architecture.md#Code-Organization]
- [Source: docs/architecture.md#Naming-Conventions]
- [Source: docs/architecture.md#Project-Initialization]
- [Source: docs/architecture.md#Technology-Stack-Details]

## Dev Agent Record

### Context Reference

<!-- Path(s) to story context XML will be added here by context workflow -->

### Agent Model Used

GPT-5 (Codex CLI)

### Debug Log References

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created
- Implemented VPC, public/private subnet, NAT gateway, EIP association, SNAT entries, and base security group resources with required providers.
- Added required networking variables/validations and outputs for VPC, subnets, NAT gateway, and security groups.
- Tests: `python3 tests/foundation_network_test.py`, `python3 tests/scaffold_structure_test.py`, `python3 tests/remote_state_test.py`.
- Documented module inputs/outputs, example usage, and dependency notes in README.
- Tests: `python3 tests/foundation_network_readme_test.py`.
- Aligned resource naming with module prefix conventions; confirmed module remains env-agnostic.
- Tests: `python3 tests/foundation_network_naming_test.py`.
- Validation: `terraform fmt -check` passed locally; `terraform validate` confirmed by user in `infra/envs/dev`.
- `tflint` not configured in repo.
- Wired dev/prod environment inputs for foundation-network and refreshed example tfvars.
- Regression tests rerun: `python3 tests/foundation_network_test.py`, `python3 tests/foundation_network_readme_test.py`, `python3 tests/foundation_network_naming_test.py`, `python3 tests/scaffold_structure_test.py`, `python3 tests/remote_state_test.py`.
- Added outputs for resource names (VPC, subnets, NAT gateway, security group) to meet AC1.
- Validation: `terraform validate` confirmed by user in `infra/modules/foundation-network`.
- Apply troubleshooting: switched NAT to Enhanced, avoided pay-by-spec, and passed `nat_gateway_type` from env; apply succeeded after updates.

### File List

- docs/sprint-artifacts/3-2-implement-foundation-network-module.md
- infra/modules/foundation-network/README.md
- infra/modules/foundation-network/main.tf
- infra/modules/foundation-network/outputs.tf
- infra/modules/foundation-network/variables.tf
- infra/envs/dev/dev.tfvars.example
- infra/envs/dev/main.tf
- infra/envs/dev/variables.tf
- infra/envs/dev/.terraform.lock.hcl
- infra/envs/prod/main.tf
- infra/envs/prod/prod.tfvars.example
- infra/envs/prod/variables.tf
- infra/envs/dev/dev.tfvars
- tests/foundation_network_test.py
- tests/foundation_network_readme_test.py
- tests/foundation_network_naming_test.py
- docs/sprint-artifacts/sprint-status.yaml

### Change Log

- 2025-12-30: Implemented foundation-network module, documentation, env wiring, validation notes, and resource name outputs.
- 2025-12-30: Code review fixes applied and validations confirmed; story marked done.
- 2025-12-30: Resolved NAT gateway apply errors (Enhanced NAT + pay-by-CU) and documented env wiring for nat_gateway_type.
