# Prod Remote State Migration Guide

Use this procedure to wire the prod environment to the shared OSS bucket/TableStore created in Story 1.1.

## Prerequisites
- Terraform CLI 1.6.x+ and AliCloud provider >= 1.200.
- CloudSSO login using profile `CloudSSOProfile` (`aliyun configure sso --profile CloudSSOProfile`).
- Access to the bootstrap workspace outputs.

## 1. Capture Bootstrap Outputs

```bash
tf_cmd="terraform -chdir=infra/bootstrap/remote-state output -raw"
OSS_BUCKET=$($tf_cmd oss_bucket_name)
LOCK_TABLE=$($tf_cmd lock_table_name)
OTS_ENDPOINT=$($tf_cmd ots_endpoint)
```

## 2. Craft backend.hcl

```bash
cp infra/envs/prod/backend.hcl.example infra/envs/prod/backend.hcl
sed -i '' "s/<terraform output -raw oss_bucket_name>/$OSS_BUCKET/" infra/envs/prod/backend.hcl
sed -i '' "s/<terraform output -raw lock_table_name>/$LOCK_TABLE/" infra/envs/prod/backend.hcl
sed -i '' "s#<terraform output -raw ots_endpoint>#$OTS_ENDPOINT#" infra/envs/prod/backend.hcl
```

- Keep `key = "envs/prod/terraform.tfstate"` so prod state never collides with dev.
- Bucket + TableStore identifiers should remain kebab-case/snake_case to follow architecture guidelines.

## 3. Init + migrate

```bash
cd infra/envs/prod
terraform init -backend-config=backend.hcl -migrate-state
terraform plan
```

Running `terraform plan` twice in separate shells should show the second process blocking with a TableStore lock notice. Abort after confirming the lock works.

## Troubleshooting
- **Expired CloudSSO session**: rerun `aliyun configure sso --profile CloudSSOProfile`.
- **Stale lock**: use `terraform force-unlock <LOCK_ID>` or delete the row from TableStore with the CLI command shown in the dev guide.
- **Bucket/key mismatch**: re-run bootstrap outputs to confirm names; never hard-code guesses.

Document any deviations here so CI/CD remains in sync with manual steps.
