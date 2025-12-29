# Remote State Bootstrap Module

Bootstrap OSS + TableStore so every Terraform stack can migrate into a shared backend before other modules run.

## Prerequisites

1. Finish `bootstrap-1-cloudsso` and authenticate with your CloudSSO profile (default `CloudSSOProfile`).
2. Populate `infra/bootstrap/remote-state/terraform.tfvars` (see example below).
3. Run the module using local Terraform state.

## Usage

```bash
cd infra/bootstrap/remote-state
terraform init
terraform apply -var-file=terraform.tfvars
```

### Example `terraform.tfvars`

```hcl
region                    = "ap-southeast-1"
profile                   = "CloudSSOProfile"
bucket_name               = "tfstate-sandbox"
table_store_instance_name = "tfstate-sandbox"
lock_table_name           = "terraform_state_lock"
table_store_description   = "Terraform remote state locking"
tags = {
  project = "ali-infrastructure"
  env     = "bootstrap"
}
```

### Outputs

- `remote_state_bucket` – OSS bucket storing Terraform state (private, versioned, AES256).
- `tablestore_instance_name` – OTS instance used for state locking.
- `lock_table_name` – Table that stores Terraform locks (`LockID` primary key).
- `tablestore_endpoint` – HTTPS endpoint needed when configuring backend.hcl.

Record these values in a secure location; downstream env stacks will reference them when configuring the OSS backend.

## Backend Migration Reference

After this module runs, each environment stack should:

1. Declare `terraform { backend "oss" {} }` in `infra/envs/<env>/backend.tf`.
2. Create `backend.hcl.example` with the outputs from this module (see env scaffolding for templates).
3. Run `terraform init -backend-config=backend.hcl -migrate-state` to switch existing stacks.

See `/infra/envs/dev` and `/infra/envs/prod` for concrete backend examples referencing the outputs above.
