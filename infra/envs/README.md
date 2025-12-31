# Environment Backend Wiring

Each environment stack consumes the remote state bootstrap outputs and declares an `oss` backend using the pattern below.

## Steps

1. Copy the appropriate `backend.hcl.example` to `backend.hcl` inside `infra/envs/<env>/`.
2. Adjust `key` if the state path should differ per stack.
3. Run Terraform init/migrate:

```bash
cd infra/envs/<env>
terraform init -backend-config=backend.hcl -migrate-state
```

Use the same CloudSSO profile (`CloudSSOProfile` by default) so Terraform can reach the OSS bucket `tfstate-sandbox` and the TableStore endpoint `https://tfstate-sandbox.ap-southeast-1.ots.aliyuncs.com`.

## Notes / Common Issues

- If `terraform init` fails with `InvalidAccessKeyId`, ensure the `profile` value in `backend.hcl` matches the profile you exported.
- The `scripts/export-aliyun-profile.sh` script must be **sourced** to persist environment variables in the current shell:
  ```bash
  source scripts/export-aliyun-profile.sh <profile-name>
  ```
- The script exports `ALICLOUD_ACCESS_KEY`, `ALICLOUD_SECRET_KEY`, and `ALICLOUD_SECURITY_TOKEN`.
- `dev.tfvars.example` is not auto-loaded. Use `terraform plan -var-file=dev.tfvars` or rename to `terraform.tfvars`.
