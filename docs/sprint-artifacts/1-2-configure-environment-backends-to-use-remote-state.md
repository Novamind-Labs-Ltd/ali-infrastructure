# Story 1.2: Configure Environment Backends to Use Remote State

Status: done

## Story

As a platform engineer,
I want each environment stack to load backend configuration from the bootstrap outputs,
so that Terraform init migrates state into the shared OSS bucket with TableStore locking. [Source: docs/epics.md]

## Acceptance Criteria

1. **Given** `infra/envs/dev/` and `infra/envs/prod/` exist **when** I open each folder **then** I see `backend.tf` declaring `backend "oss" {}` and a `backend.hcl.example` referencing bucket, region, key, and TableStore endpoint placeholders. [Source: docs/epics.md]
2. **Given** bootstrap outputs are available **when** I run `terraform init -backend-config=backend.hcl` in either environment **then** state migrates (or initializes) into the OSS bucket and confirms TableStore locking is active. [Source: docs/epics.md]

## Tasks / Subtasks

- [x] Wire OSS backend definitions into each environment stack (AC: #1)
  - [x] Add/verify `backend.tf` under `infra/envs/dev` and `infra/envs/prod` declaring the empty `backend "oss" {}` block so Terraform expects remote state. [Source: docs/architecture.md]
  - [x] Provide `backend.hcl.example` in each environment folder with placeholders for `region`, `bucket`, `key`, `profile`, `tablestore_table`, and `tablestore_endpoint`, referencing how to paste actual values from the bootstrap outputs produced in Story 1.1. [Source: docs/guideline/boostrap-2-remote-state.md]
- [x] Document bootstrap output consumption and migration workflow (AC: #2)
  - [x] In each environment folder README (or create `REMOTE_STATE.md` if README absent) describe how to run `terraform init -backend-config=backend.hcl -migrate-state`, including CloudSSO profile requirements and naming conventions for OSS keys per environment. [Source: docs/guideline/boostrap-2-remote-state.md]
  - [x] Capture verification steps (plan twice concurrently to confirm TableStore locking) plus troubleshooting guidance for lock contention, linking back to TableStore key names. [Source: docs/guideline/boostrap-2-remote-state.md]
- [x] Confirm developer-ready examples (AC: #2)
  - [x] Provide sample `backend.hcl` snippets (commented) inside each environment folder plus CLI snippets in docs so DevOps can copy/paste commands. [Source: docs/architecture.md]
  - [x] Ensure `infra/envs/dev` and `infra/envs/prod` reference consistent bucket naming (kebab-case) and snake_case TableStore names per ADR-001 rules. [Source: docs/architecture.md]

## Dev Notes

- Remote state bootstrap from Story 1.1 (`infra/bootstrap/remote-state/`) produced bucket + TableStore outputs; surface their variable names in the README so developers know exactly which outputs to copy. [Source: docs/guideline/boostrap-2-remote-state.md]
- `backend.tf` files must remain minimal (only declare `backend "oss" {}`) to avoid leaking credentials; all sensitive data belongs in `backend.hcl` files ignored by git, while `.example` variants show structure. [Source: docs/architecture.md]
- Enforce Terraform CLI >= 1.3 and AliCloud provider >= 1.200 per architecture decisions; call this out so implementers verify their versions before running init/migrate. [Source: docs/architecture.md]
- Document CloudSSO usage (profile `SSOProfile`) because both local engineers and CI will rely on the same workflow defined in `bootstrap-1-cloudsso`. [Source: docs/guideline/boostrap-2-remote-state.md]
- Capture lock troubleshooting guidance (e.g., how to clear a stuck lock through TableStore CLI) so future stories avoid conflicting instructions. [Source: docs/guideline/boostrap-2-remote-state.md]

## Developer Context & Guardrails

### Technical Requirements
- Treat bootstrap outputs (`oss_bucket`, `ots_instance_name`, `lock_table_name`) as authoritative inputs; do not re-create remote-state resources here. [Source: docs/guideline/boostrap-2-remote-state.md]
- Require Terraform CLI >= 1.6.x and AliCloud provider >= 1.200 to maintain compatibility with the bootstrap resources. [Source: docs/architecture.md]
- All commands must execute using the CloudSSO profile (`SSOProfile`). Failures typically indicate expired credentials; document re-auth commands. [Source: docs/guideline/boostrap-2-remote-state.md]

### Architecture Compliance
- Follow ADR-001: remote-state bootstrap happens once, all other stacks consume outputs via backend configuration files. [Source: docs/architecture.md]
- Maintain the folder structure defined in the architecture summary; new instructions must reference the canonical paths under `infra/envs/<env>`. [Source: docs/architecture.md]
- Document OSS key naming using kebab-case per architecture consistency rules. [Source: docs/architecture.md]

### Library & Tooling Requirements
- Pin Terraform + provider versions in `backend.tf` commentary, reminding developers to sync with `.terraform.lock.hcl` once modules exist. [Source: docs/architecture.md]
- Note reliance on aliyun CLI for CloudSSO plus optional TableStore CLI for lock cleanup; include install references. [Source: docs/guideline/boostrap-2-remote-state.md]

### File Structure Requirements
- Ensure `backend.tf` lives beside `main.tf` inside each environment folder; `.example` config should sit at the same level and be referenced from README instructions. [Source: docs/architecture.md]
- Add `REMOTE_STATE.md` or README sections under each env folder capturing migration procedures, keeping documentation close to code. [Source: docs/architecture.md]

### Testing Requirements
- Define smoke tests: `terraform init -backend-config=backend.hcl -migrate-state` followed by `terraform plan` for dev and prod folders. [Source: docs/epics.md]
- Instruct engineers to run two concurrent `terraform plan` commands to confirm TableStore locking prevents concurrent modification. [Source: docs/guideline/boostrap-2-remote-state.md]

### Previous Story Intelligence
- Story 1.1 established the remote-state OSS bucket and TableStore table plus documented outputs; emphasize that their output variable names (bucket, instance, table) must not change or be duplicated. [Source: docs/sprint-artifacts/1-1-bootstrap-remote-state-infrastructure.md]
- Story 1.1 left Dev Agent Record sections empty, so this story must backfill explicit documentation steps for consuming those outputs to avoid tribal knowledge gaps. [Source: docs/sprint-artifacts/1-1-bootstrap-remote-state-infrastructure.md]

### Git Intelligence Summary
- Latest commits (`dc0c39d add analysis with prd`, `b5b36fc add gitignore`) show documentation-first workflow; keep new story + README changes isolated for clear diffs. Use meaningful commit messages referencing story ID once implemented. [Source: `git log -5 --oneline`]

### Latest Technical Information
- Architecture decisions already specify minimum versions (Terraform >=1.3, AliCloud provider >=1.200). Reinforce those constraints in the story; implementers should verify the actual latest patch level before execution since this environment lacks internet access for live checks. [Source: docs/architecture.md]

### Project Context Reference
- No `project-context.md` file exists yet; call out in Dev Agent instructions that the story context workflow must generate and attach an XML reference before development begins.

## Status Update

- Story drafted with full developer context and set to **ready-for-dev**. `docs/sprint-artifacts/sprint-status.yaml` updated to mark `1-2-configure-environment-backends-to-use-remote-state` as `ready-for-dev` for Epic 1 backlog tracking.

### Project Structure Notes

- Work strictly within `infra/envs/dev` and `infra/envs/prod`, mirroring file names so future automation can template new environments. [Source: docs/architecture.md]
- Keep bootstrap artifacts isolated in `infra/bootstrap/remote-state`; reference them only via documented outputs so this story never touches bootstrap state directly. [Source: docs/architecture.md]
- Place any new environment-level docs in `infra/envs/<env>/README.md` or `docs/guideline/` to stay aligned with repo conventions. [Source: docs/architecture.md]

### References

- docs/epics.md — Epic 1 stories and acceptance criteria
- docs/architecture.md — Remote state decisions, folder conventions, ADR-001
- docs/guideline/boostrap-2-remote-state.md — Bootstrap + migration workflow details

## Dev Agent Record

### Context Reference
- No `project-context.md` present; relied on story Dev Notes and architecture docs.

### Agent Model Used
- gpt-5-codex

### Debug Log References
- `terraform init -backend-config=backend.hcl -migrate-state` (ran in `infra/envs/dev` to confirm OSS backend works with CloudSSO STS exports)

### Completion Notes List
- Replaced both environment `backend.hcl.example` files with placeholder-friendly templates plus inline commands that point to Story 1.1 outputs.
- Authored `infra/envs/dev/REMOTE_STATE.md` and `infra/envs/prod/REMOTE_STATE.md` covering bootstrap output extraction, `terraform init -backend-config=backend.hcl -migrate-state`, and TableStore lock verification/troubleshooting.
- Ensured dev/prod instructions standardize on `CloudSSOProfile`, kebab-case OSS bucket naming, and snake_case TableStore identifiers per ADR-001.

### File List
- `infra/envs/dev/backend.hcl.example`
- `infra/envs/dev/REMOTE_STATE.md`
- `infra/envs/prod/backend.hcl.example`
- `infra/envs/prod/REMOTE_STATE.md`
- `scripts/export-aliyun-profile.sh`
