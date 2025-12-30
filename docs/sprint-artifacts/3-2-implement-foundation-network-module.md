# Story 3.2: Implement Foundation Network Module

Status: ready-for-dev

## Story

As a platform engineer,
I want a Terraform module that provisions the VPC, subnets, and security groups required for ACK,
so that any environment stack can reuse consistent networking primitives.

## Acceptance Criteria

1. **Given** inputs for CIDR ranges, zones, and tags **when** I apply the `foundation-network` module **then** it creates an AliCloud VPC, public/private subnets, NAT gateway, and security groups with outputs for IDs and resource names. [Source: docs/epics.md#Story-32-Implement-Foundation-Network-Module]
2. **Given** module documentation requirements **when** the module is published **then** its README lists inputs/outputs, example usage, and dependency notes. [Source: docs/epics.md#Story-32-Implement-Foundation-Network-Module]

## Tasks / Subtasks

- [ ] Implement `infra/modules/foundation-network/` Terraform module (AC: 1)
  - [ ] Add `main.tf` with AliCloud VPC, subnets (public/private), NAT gateway, and security groups
  - [ ] Add `variables.tf` defining CIDR ranges, zones, and tagging inputs
  - [ ] Add `outputs.tf` exporting VPC ID, subnet IDs, NAT gateway ID, and security group IDs
- [ ] Provide module documentation (AC: 2)
  - [ ] Update `infra/modules/foundation-network/README.md` with inputs/outputs tables, example usage, and dependency notes
- [ ] Align with architecture conventions (AC: 1, 2)
  - [ ] Use snake_case variable names and kebab-case directory names
  - [ ] Keep module focused on reusable networking primitives (no environment-specific wiring)
- [ ] Validate module quality before handoff (AC: 1)
  - [ ] Run `terraform fmt` and `terraform validate` for the module directory
  - [ ] Run `tflint` if configured for this repo

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

### File List

- docs/sprint-artifacts/3-2-implement-foundation-network-module.md
