# bootstrap-2-remote-state

> Goal: Using the **CloudSSO-backed local CLI profile** (from `bootstrap-1-cloudsso`), bootstrap Terraform **remote state** on Alibaba Cloud:
>
> * **OSS bucket** to store Terraform state
> * **Tablestore (OTS) table** to provide state **locking**
>
> Approach: **Two-stage Terraform bootstrap**
>
> 1. Use **local state** to create the remote-state resources (OSS + OTS)
> 2. Switch Terraform to use **OSS backend** (remote state + locking)

---

## 0. Prerequisites

* You completed `bootstrap-1-cloudsso`
* You have a working CLI profile, e.g. `SSOProfile`
* Validate before starting:

```bash
aliyun sts GetCallerIdentity --profile SSOProfile
```

---

## 1. Stage A — Create remote-state resources using local Terraform state

### 1.1 Create a dedicated bootstrap folder

Recommended structure:

```text
infra/
  bootstrap/
    remote-state/
      main.tf
      variables.tf
      terraform.tfvars
```

### 1.2 Terraform configuration (local state)

Create `main.tf`:

```hcl
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.200.0"
    }
  }
}

provider "alicloud" {
  region  = var.region
  profile = var.aliyun_profile
}

variable "region" {
  type    = string
  default = "cn-hongkong"
}

variable "aliyun_profile" {
  type    = string
  default = "SSOProfile"
}

variable "bucket_name" {
  type = string
  # Example: novamind-tfstate-cn-hongkong
}

variable "lock_table_name" {
  type    = string
  default = "terraform-state-lock"
}

# --- OSS bucket for Terraform state ---
resource "alicloud_oss_bucket" "tf_state" {
  bucket = var.bucket_name
  acl    = "private"

  versioning {
    status = "Enabled"
  }

  server_side_encryption_rule {
    sse_algorithm = "AES256"
  }
}

# --- Tablestore (OTS) instance + lock table ---
resource "alicloud_ots_instance" "lock" {
  name        = "${var.bucket_name}-ots"
  description = "Terraform remote state locking"
}

resource "alicloud_ots_table" "lock" {
  instance_name = alicloud_ots_instance.lock.name
  table_name    = var.lock_table_name

  primary_key {
    name = "LockID"
    type = "String"
  }
}

output "oss_bucket" {
  value = alicloud_oss_bucket.tf_state.bucket
}

output "ots_instance_name" {
  value = alicloud_ots_instance.lock.name
}

output "lock_table_name" {
  value = alicloud_ots_table.lock.table_name
}
```

Create `terraform.tfvars`:

```hcl
region        = "cn-hongkong"
aliyun_profile = "SSOProfile"
bucket_name   = "REPLACE_WITH_YOUR_UNIQUE_BUCKET_NAME"
```

### 1.3 Apply (creates bucket + lock table)

```bash
terraform init
terraform apply
```

Record outputs:

* `oss_bucket`
* `ots_instance_name`
* `lock_table_name`

---

## 2. Stage B — Switch your real infra stacks to OSS backend (remote state + locking)

### 2.1 Add a backend block to your main infra stack

In your main Terraform stack (not the bootstrap folder), add:

`backend.tf`

```hcl
terraform {
  backend "oss" {}
}
```

### 2.2 Create a backend config file

Create `backend.hcl` (do **not** commit if you treat it as environment-specific):

```hcl
region = "cn-hongkong"
bucket = "REPLACE_WITH_OUTPUT_oss_bucket"
key    = "state/bootstrap/terraform.tfstate"

profile = "SSOProfile"

tablestore_table    = "terraform-state-lock"
tablestore_endpoint = "https://REPLACE_WITH_OTS_INSTANCE.cn-hongkong.ots.aliyuncs.com"
```

Notes:

* `key` should be a stable path per stack/environment
* `tablestore_endpoint` format includes your OTS instance name and region

### 2.3 Initialize and migrate state

If your stack already has local state:

```bash
terraform init -backend-config=backend.hcl -migrate-state
```

If it’s new:

```bash
terraform init -backend-config=backend.hcl
```

---

## 3. Recommended state key conventions

Pick one convention and standardize it:

### Option A — per environment folder

* `state/dev/<stack>.tfstate`
* `state/prod/<stack>.tfstate`

### Option B — Terraform workspaces

* `state/<stack>/terraform.tfstate` (workspace suffix managed by Terraform)

For most teams, **Option A** is more explicit and easier to audit.

---

## 4. Verification checklist

### 4.1 Backend is working

Run in the main stack:

```bash
terraform plan
```

Then confirm in OSS Console:

* state object exists under the configured `key`

### 4.2 Locking works

In two terminals, run `terraform plan` concurrently on the same stack.
One should acquire the lock; the other should wait/fail with a lock message.

---

## 5. Operational notes

* CloudSSO credentials are temporary. If commands start failing, re-auth by running:

  ```bash
  aliyun configure --profile SSOProfile --mode CloudSSO
  ```

  (or re-run the CloudSSO auth flow prompted by the CLI)
* Do not commit secrets. Prefer committing a `backend.hcl.example` and keeping real `backend.hcl` local.

---

## 6. Done Criteria

* [x] OSS bucket for state created and versioning enabled
* [x] OTS instance and lock table created
* [x] Main Terraform stacks successfully use `backend "oss"`
* [x] State locking verified
