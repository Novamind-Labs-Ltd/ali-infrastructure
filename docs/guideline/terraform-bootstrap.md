# Alicloud Terraform Bootstrap Guide

Steps for preparing Alicloud so Terraform code (run locally or via GitHub Actions) can deploy infrastructure safely using an OSS remote backend and Alicloud CLI credentials. Run these once per environment, then reference the created resources from Terraform.

---

## 1. Prerequisites

1. Main/root account access (or a RAM admin role) to create buckets, tables, and policies.
2. Region decided for state (usually same region as infra, e.g., `ap-southeast-1`).
3. Naming convention, e.g., `novamind-tfstate-<env>` for buckets and `novamind-tf-lock-<env>` for TableStore.

---

## 2. Local Workstation Setup

1. **Install Terraform** – Download from HashiCorp or `brew install terraform`; target v1.5+.
2. **Install Alicloud CLI** – `brew install aliyun` (macOS) or download from https://github.com/aliyun/aliyun-cli.
3. **Configure CLI profile**
   ```bash
   aliyun configure --profile novamind-devops \
     --mode AK \
     --access-key-id <AccessKeyId> \
     --access-key-secret <AccessKeySecret> \
     --region ap-southeast-1
   ```
   - Prefer temporary credentials via `AssumeRole` if MFA/SSO is required: `aliyun sts AssumeRole` and set `ALIBABA_CLOUD_ACCESS_KEY_ID/SECRET/SECURITY_TOKEN`.
4. **Install ossutil (optional but recommended)** – needed for bucket management: https://help.aliyun.com/document_detail/120075.html.

---

## 3. Remote State Storage (OSS + Lock Table)

1. **Create OSS bucket** (per environment):
   ```bash
   BUCKET=novamind-tfstate-dev
   REGION=ap-southeast-1
   aliyun oss mb oss://$BUCKET --region $REGION
   aliyun oss bucket-versioning --bucket-name $BUCKET --status Enabled
   aliyun oss bucket-encryption --bucket-name $BUCKET --sse AES256
   ```
2. **Create TableStore instance & table for state locking** (Terraform OSS backend supports TableStore):
   ```bash
   INSTANCE=tf-lock-dev
   TABLE=tfstate-lock
   aliyun ots CreateInstance --InstanceName $INSTANCE --RegionId $REGION
   aliyun ots CreateTable --InstanceName $INSTANCE --TableMeta '{
     "table_name": "'"$TABLE"'",
     "primary_key_schema": [{"name": "LockID","type": "STRING"}]
   }'
   ```
   - Alternatively use DynamoDB-compatible service (TableStore recommended by Alicloud).
3. **Create RAM policy** allowing read/write on the bucket + TableStore:
   ```json
   {
     "Version": "1",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "oss:ListObjects",
           "oss:GetObject",
           "oss:PutObject",
           "oss:DeleteObject"
         ],
         "Resource": [
           "acs:oss:*:*:novamind-tfstate-dev",
           "acs:oss:*:*:novamind-tfstate-dev/*"
         ]
       },
       {
         "Effect": "Allow",
         "Action": [
           "ots:GetRow",
           "ots:PutRow",
           "ots:DeleteRow"
         ],
         "Resource": "acs:ots:*:*:instance/tf-lock-dev/table/tfstate-lock"
       }
     ]
   }
   ```
   Attach this to:
   - DevOps RAM group so local `terraform` commands can access state.
   - GitHub Actions role (`GitHubActionsDeploy`) so CI/CD can lock and modify state.

---

## 4. Terraform Backend Configuration

Add a backend block in each root module (prefer using partial configuration + `backend.hcl` so secrets stay out of VCS):

```hcl
# backend.hcl (not committed)
bucket        = "novamind-tfstate-dev"
key           = "network/terraform.tfstate"
region        = "ap-southeast-1"
prefix        = "tfstate-dev"
tablestore_endpoint = "https://tf-lock-dev.ap-southeast-1.ots.aliyuncs.com"
tablestore_table    = "tfstate-lock"
```

```hcl
# main.tf
terraform {
  backend "oss" {}
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1.214"
    }
  }
}
```

Initialize:

```bash
terraform init -backend-config=backend.hcl
```

---

## 5. Bootstrapping Workflow

1. Log in with the main/root account (console or CLI).
2. Create OSS bucket + TableStore + RAM policy as above (repeat per env: dev/stg/prod).
3. Attach the policy to:
   - `DevOpsAdmin` group (human operators).
   - `GitHubActionsDeploy` role (CI/CD).
4. Configure local CLI profile (Section 2) or rely on RAM role SSO.
5. Populate `backend.hcl` with bucket/table settings.
6. Run `terraform init` locally to confirm state access.
7. Update GitHub workflow to supply the same backend config (via environment secrets or generated file) before running `terraform init/plan/apply`.

---

## 6. Verification Checklist

- [ ] OSS bucket exists, versioning + SSE enabled.
- [ ] TableStore instance/table created for locking.
- [ ] RAM policy attached to DevOps group and GitHub role.
- [ ] Local `aliyun` CLI profile set up; `aliyun sts GetCallerIdentity` works.
- [ ] `terraform init` completes using remote backend.
- [ ] GitHub Action deploy job runs `terraform init/plan` successfully.

