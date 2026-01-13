# OSS Bucket Module

Terraform module for creating an Alibaba Cloud OSS bucket with optional Imgix integration support.

## Features

- OSS bucket with configurable ACL (private or public-read)
- CORS configuration for CDN access
- Optional lifecycle rules for cost optimization
- Optional RAM user with read-only access for Imgix S3-compatible source
- Outputs for both S3-compatible and Web Folder Imgix integration

## Usage

### Basic Usage (Private Bucket with Imgix)

```hcl
module "oss_imgix" {
  source = "../../modules/oss-bucket"

  environment = "dev"
  name_prefix = "novamind"
  region      = "ap-southeast-1"

  acl             = "private"
  create_ram_user = true
  ram_user_name   = "imgix-oss-reader-dev"

  tags = {
    environment = "dev"
    managed_by  = "terragrunt"
    purpose     = "imgix-images"
  }
}
```

### Public Bucket (Web Folder Fallback)

```hcl
module "oss_imgix" {
  source = "../../modules/oss-bucket"

  environment = "dev"
  name_prefix = "novamind"
  region      = "ap-southeast-1"

  acl             = "public-read"
  create_ram_user = false

  tags = {
    environment = "dev"
    managed_by  = "terragrunt"
  }
}
```

### With Lifecycle Rules

```hcl
module "oss_imgix" {
  source = "../../modules/oss-bucket"

  environment = "dev"
  name_prefix = "novamind"
  region      = "ap-southeast-1"

  lifecycle_rules = [
    {
      id                       = "archive-old-images"
      prefix                   = "archive/"
      enabled                  = true
      transition_days          = 90
      transition_storage_class = "IA"
      expiration_days          = null
    },
    {
      id                       = "delete-temp"
      prefix                   = "temp/"
      enabled                  = true
      expiration_days          = 7
      transition_days          = null
      transition_storage_class = null
    }
  ]

  tags = {
    environment = "dev"
  }
}
```

## Imgix Integration

### Option 1: S3-Compatible Source (Private Bucket)

After applying, create access key for the RAM user manually:

```bash
# Get RAM user name from Terraform output
terragrunt output ram_user_name

# Create access key via Alibaba Cloud CLI
aliyun ram CreateAccessKey --UserName imgix-oss-reader-dev

# ⚠️ Save the AccessKeyId and AccessKeySecret immediately!
# The secret is only shown once and cannot be retrieved again.
```

Then configure Imgix using the Management API:

```json
{
  "data": {
    "attributes": {
      "name": "novamind-images",
      "deployment": {
        "type": "s3",
        "s3_bucket": "<bucket_name>",
        "s3_access_key": "<AccessKeyId>",
        "s3_secret_key": "<AccessKeySecret>",
        "s3_prefix": ""
      },
      "imgix_subdomains": ["novamind-images"]
    },
    "type": "sources"
  }
}
```

**Note:** This approach may not work if Imgix validates AWS-specific endpoints.

### Option 2: Web Folder Source (Public Bucket)

If S3-compatible doesn't work, use Web Folder:

1. Change `acl` to `"public-read"`
2. Set `create_ram_user = false`
3. In Imgix Dashboard:
   - Create new **Web Folder** source
   - Base URL: Use `imgix_web_folder_url` output
   - No credentials needed

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (e.g., dev, prod) | `string` | n/a | yes |
| name_prefix | Prefix for naming resources | `string` | n/a | yes |
| region | Alibaba Cloud region | `string` | n/a | yes |
| acl | Bucket ACL (private, public-read) | `string` | `"private"` | no |
| storage_class | Storage class | `string` | `"Standard"` | no |
| force_destroy | Force destroy bucket with objects | `bool` | `false` | no |
| tags | Resource tags | `map(string)` | `{}` | no |
| enable_cors | Enable CORS | `bool` | `true` | no |
| cors_allowed_methods | CORS allowed methods | `list(string)` | `["GET", "HEAD"]` | no |
| cors_allowed_origins | CORS allowed origins | `list(string)` | `["*"]` | no |
| cors_allowed_headers | CORS allowed headers | `list(string)` | `["*"]` | no |
| cors_max_age_seconds | CORS max age | `number` | `3600` | no |
| lifecycle_rules | Lifecycle rules | `list(object)` | `[]` | no |
| create_ram_user | Create RAM user for Imgix | `bool` | `true` | no |
| ram_user_name | RAM user name | `string` | `"imgix-oss-reader"` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_name | OSS bucket name |
| bucket_id | OSS bucket ID |
| bucket_acl | Bucket ACL |
| bucket_endpoint | Public endpoint URL |
| bucket_internal_endpoint | Internal endpoint URL |
| imgix_s3_endpoint | S3-compatible endpoint for Imgix |
| imgix_web_folder_url | Web Folder URL for Imgix |
| ram_user_name | RAM user name (create access key manually) |
| ram_policy_name | RAM policy name |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| alicloud | >= 1.223.0 |

## Notes

- `alicloud_oss_bucket_acl` cannot be destroyed by Terraform. Removing from config only removes from state.
- **Access keys are NOT created by Terraform** to avoid storing secrets in state. Create manually via CLI or Console after deployment.
- For production, consider enabling versioning and server-side encryption.
