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
