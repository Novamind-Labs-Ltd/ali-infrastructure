# Dev Remote State Migration Guide

Follow these steps to point the dev environment at the shared OSS backend created in Story 1.1.

## Prerequisites
- Terraform CLI 1.6.x or newer installed locally.
- AliCloud provider >= 1.200 available (handled automatically by `terraform init`).
- Logged in via CloudSSO profile `CloudSSOProfile` (`aliyun configure sso --profile CloudSSOProfile`).

## 1. Capture Bootstrap Outputs
Run the bootstrap module outputs to collect the bucket + TableStore values (read-only):

```bash
tf_cmd="terraform -chdir=infra/bootstrap/remote-state output -raw"
OSS_BUCKET=$($tf_cmd oss_bucket_name)
LOCK_TABLE=$($tf_cmd lock_table_name)
OTS_ENDPOINT=$($tf_cmd ots_endpoint)
```

## 2. Create backend.hcl
Copy the example file, then replace the placeholders with the values retrieved above:

```bash
cp infra/envs/dev/backend.hcl.example infra/envs/dev/backend.hcl
sed -i '' "s/<terraform output -raw oss_bucket_name>/$OSS_BUCKET/" infra/envs/dev/backend.hcl
sed -i '' "s/<terraform output -raw lock_table_name>/$LOCK_TABLE/" infra/envs/dev/backend.hcl
sed -i '' "s#<terraform output -raw ots_endpoint>#$OTS_ENDPOINT#" infra/envs/dev/backend.hcl
```

Key naming guidance:
- `key` should remain `envs/dev/terraform.tfstate` unless you need a different state file path.
- Bucket and TableStore identifiers must stay kebab-case and snake_case respectively per ADR-001.

## 3. Migrate or Initialize State
From the dev environment folder, run Terraform init with migrate turned on (safe for first-time init):

```bash
cd infra/envs/dev
terraform init -backend-config=backend.hcl -migrate-state
terraform plan
```

Use the same `CloudSSOProfile` profile; failures usually mean CloudSSO credentials expired—rerun the login command and retry.

## 4. Verify TableStore Locking
Open two shells and run `terraform plan` concurrently. The second shell should block with a lock message referencing `terraform_state_lock`. Cancel (Ctrl+C) to release the lock and continue. This proves TableStore locking is wired up.

## Troubleshooting Locks
If a lock is stuck:
1. Attempt `terraform force-unlock <LOCK_ID>` from the same folder.
2. As a last resort, delete the record from TableStore using the Aliyun console or TableStore CLI command:
   ```bash
   ots-cli delete-row \
     --instance-name "$OSS_BUCKET" \
     --table-name "$LOCK_TABLE" \
     --primary-key '{"LockID":{"S":"<LOCK_ID>"}}'
   ```
   Ensure no one else is actively running Terraform before removing the lock.

Keep this file up-to-date whenever bootstrap outputs or naming conventions change.
