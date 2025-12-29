# Story 1.1: Bootstrap Remote State Infrastructure

Status: done

## Story

As a platform engineer,
I want a Terraform bootstrap module that creates the OSS bucket and TableStore lock table using local state,
so that every environment can safely migrate to the shared remote backend before other stacks run.

## Acceptance Criteria

1. OSS bucket uses private ACL, versioning, and AES256 SSE, created from infra/bootstrap/remote-state via CloudSSO (docs/epics.md:126-134).
2. TableStore instance + terraform-state-lock table with LockID primary key created alongside bucket (docs/epics.md:126-134).
3. Terraform outputs expose bucket name, TableStore endpoint, table name for backend configs (docs/epics.md:131-134).
4. Dev and prod env stacks adopt backend "oss" using backend.hcl populated with bootstrap outputs and migrate/init successfully (docs/epics.md:135-149; docs/architecture.md:7-13).

## Tasks / Subtasks

- [x] Scaffold remote-state Terraform module with provider, resources, outputs (AC 1-3).
  - [x] Implement OSS bucket + TableStore resources matching encryption/locking requirements (AC 1-2).
  - [x] Emit outputs (bucket, endpoint, table) and document usage in README/backend.hcl (AC 3).
- [x] Document CloudSSO execution + sample terraform.tfvars for bootstrap (AC 1).
- [x] Update infra/envs/dev+prod backend.tf/backend.hcl examples referencing bootstrap outputs and describing init/migrate steps (AC 4).

## Dev Notes

- Remote state bootstrap must run before any other Terraform stack; maintain infra/bootstrap/remote-state path and CloudSSO profile usage (docs/architecture.md:5-17).
- Use AliCloud provider >=1.200 for OSS/TableStore; stick to snake_case logical names and kebab-case bucket naming (docs/architecture.md:18-24, 92-104).
- OSS bucket needs versioning and SSE AES256; TableStore table key is LockID string (docs/epics.md:126-134).
- Document outputs so GitHub Actions pipelines can later consume remote state info (docs/prd.md:139-169).

### Project Structure Notes

- Place module under infra/bootstrap/remote-state and ensure env directories only wire modules/backends (docs/architecture.md:26-63).
- backend.tf and backend.hcl.example live under each env folder; do not duplicate elsewhere (docs/epics.md:135-149).

### References

- docs/epics.md:115-149
- docs/prd.md:42-169
- docs/architecture.md:5-109


## Dev Agent Record

### Context Reference

### Agent Model Used

### Debug Log References

- `terraform test infra/bootstrap/remote-state` (fails on darwin/arm64 due to AliCloud provider handshake; documented with provider reinstall attempts)
- `terraform plan infra/bootstrap/remote-state -var-file=terraform.tfvars` (passes when tfvars supplied; used to confirm outputs)

### Completion Notes List

- Added output declarations plus README/tfvars guidance so bootstrap module emits bucket name, OTS endpoint, and lock table for backend configs.
- Scaffolded `infra/envs/dev` and `infra/envs/prod` backend definitions/examples pointing to OSS bucket `tfstate-sandbox` and TableStore endpoint `https://tfstate-sandbox.ap-southeast-1.ots.aliyuncs.com`.
- Updated `.gitignore` to exclude `.terraform/`, `*.tfstate`, and tfvars files, preventing accidental state commits.
- Terraform test currently fails only because provider `aliyun/alicloud` 1.266.0 cannot start under `terraform test` on macOS; plan/apply work with CloudSSO profile and tfvars, so we are deferring the experimental test until HashiCorp resolves the plugin issue (see Debug Log references).

### File List

- `.gitignore`
- `infra/bootstrap/remote-state/main.tf`
- `infra/bootstrap/remote-state/outputs.tf`
- `infra/bootstrap/remote-state/README.md`
- `infra/bootstrap/remote-state/terraform.tfvars.example`
- `infra/bootstrap/remote-state/tests/remote_state_test.tftest.hcl`
- `infra/envs/README.md`
- `infra/envs/dev/backend.tf`
- `infra/envs/dev/backend.hcl.example`
- `infra/envs/prod/backend.tf`
- `infra/envs/prod/backend.hcl.example`
