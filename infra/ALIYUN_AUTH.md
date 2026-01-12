# Alibaba Cloud Authentication Guide

This guide covers how to set up Alibaba Cloud authentication for local development.

## Prerequisites

### Install Aliyun CLI

```bash
# macOS
brew install aliyun-cli

# Or download from https://github.com/aliyun/aliyun-cli/releases
```

### Install Terraform Alicloud Provider

The provider is automatically downloaded when you run `terraform init` or `terragrunt init`.

## Authentication Methods

### Method 1: CLI Profile (Recommended)

Create a named profile for each environment:

```bash
# Dev environment
aliyun configure --profile novamind-sandbox-kun

# You'll be prompted for:
# - Access Key ID
# - Access Key Secret
# - Region (e.g., ap-southeast-1)
# - Language (en)
```

For production (separate credentials):

```bash
aliyun configure --profile novamind-prod
```

**Verify profile:**

```bash
aliyun configure list
aliyun sts GetCallerIdentity --profile novamind-sandbox-kun
```

### Method 2: Environment Variables

Export credentials directly (useful for CI/CD):

```bash
export ALICLOUD_ACCESS_KEY="your-access-key-id"
export ALICLOUD_SECRET_KEY="your-access-key-secret"
export ALICLOUD_REGION="ap-southeast-1"

# Optional: Use a specific profile
export ALICLOUD_PROFILE="novamind-sandbox-kun"
```

### Method 3: Credentials File

Create `~/.aliyun/credentials`:

```ini
[default]
access_key_id = your-access-key-id
access_key_secret = your-access-key-secret
region_id = ap-southeast-1

[novamind-sandbox-kun]
access_key_id = your-dev-access-key-id
access_key_secret = your-dev-access-key-secret
region_id = ap-southeast-1

[novamind-prod]
access_key_id = your-prod-access-key-id
access_key_secret = your-prod-access-key-secret
region_id = ap-southeast-1
```

## Using with Terragrunt

### Profile-based (Default)

The `env.hcl` files specify which profile to use:

```hcl
# live/dev/env.hcl
locals {
  remote_state_profile = "novamind-sandbox-kun"
}

# live/prod/env.hcl
locals {
  remote_state_profile = "novamind-prod"
}
```

### Environment Variable Override

Override the profile via environment variable:

```bash
# Use a different profile
export ALICLOUD_PROFILE=my-other-profile
cd infra/live/dev/foundation-network
terragrunt plan
```

### CI/CD Setup

For CI/CD pipelines, use environment variables:

```bash
export ALICLOUD_ACCESS_KEY="${ALICLOUD_ACCESS_KEY}"
export ALICLOUD_SECRET_KEY="${ALICLOUD_SECRET_KEY}"
export ALICLOUD_REGION="ap-southeast-1"

# Override state bucket if needed
export TG_STATE_BUCKET="tfstate-ci"

cd infra/live/dev
terragrunt run-all plan
```

## Getting Access Keys

### From Alibaba Cloud Console

1. Log in to [Alibaba Cloud Console](https://www.alibabacloud.com/)
2. Go to **AccessKey Management** (hover on profile icon → AccessKey)
3. Click **Create AccessKey**
4. Save the Access Key ID and Secret securely

### Using RAM Users (Recommended for Teams)

1. Go to **RAM Console** → **Users**
2. Create a new RAM user
3. Attach required policies:
   - `AliyunVPCFullAccess`
   - `AliyunCSFullAccess` (for ACK)
   - `AliyunOSSFullAccess` (for state storage)
   - `AliyunOTSFullAccess` (for state locking)
4. Create AccessKey for the RAM user

### Minimum Required Permissions

For infrastructure deployment:

```json
{
  "Version": "1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "vpc:*",
        "ecs:*",
        "cs:*",
        "oss:*",
        "ots:*",
        "ram:*",
        "slb:*",
        "nat:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## Switching Between Environments

### Using Profiles

```bash
# Work on dev
cd infra/live/dev/foundation-network
terragrunt plan  # Uses novamind-sandbox-kun profile

# Work on prod
cd infra/live/prod/foundation-network
terragrunt plan  # Uses novamind-prod profile
```

### Override Profile Temporarily

```bash
# Override for a single command
ALICLOUD_PROFILE=other-profile terragrunt plan
```

## Troubleshooting

### "InvalidAccessKeyId" Error

```
Error: InvalidAccessKeyId.NotFound
```

**Fix:** Verify your access key is correct:

```bash
aliyun sts GetCallerIdentity --profile novamind-sandbox-kun
```

### "Profile not found" Error

```
Error: profile novamind-sandbox-kun not found
```

**Fix:** Create the profile:

```bash
aliyun configure --profile novamind-sandbox-kun
```

### "SignatureDoesNotMatch" Error

```
Error: SignatureDoesNotMatch
```

**Fix:** Your secret key may be incorrect. Reconfigure:

```bash
aliyun configure --profile novamind-sandbox-kun
```

### "Access Denied" Error

```
Error: Forbidden.RAM
```

**Fix:** The RAM user lacks required permissions. Attach the necessary policies in RAM Console.

### Check Current Identity

```bash
# Via CLI
aliyun sts GetCallerIdentity --profile novamind-sandbox-kun

# Via Terraform
cd infra/live/dev/foundation-network
terragrunt console
> data.alicloud_caller_identity.current
```

### Debug Authentication Issues

```bash
# Enable debug logging
export TF_LOG=DEBUG
terragrunt plan 2>&1 | grep -i "auth\|credential\|access"
```

## Security Best Practices

1. **Never commit credentials** - Use `.gitignore` for credential files
2. **Use RAM users** - Don't use root account credentials
3. **Rotate keys regularly** - Rotate access keys every 90 days
4. **Use separate credentials per environment** - Dev and prod should have different keys
5. **Use MFA for console access** - Enable MFA for Alibaba Cloud console
6. **Least privilege** - Grant only required permissions

## Quick Reference

| Task | Command |
|------|---------|
| Create profile | `aliyun configure --profile <name>` |
| List profiles | `aliyun configure list` |
| Test auth | `aliyun sts GetCallerIdentity --profile <name>` |
| Switch profile | `export ALICLOUD_PROFILE=<name>` |
| Use env vars | `export ALICLOUD_ACCESS_KEY=xxx ALICLOUD_SECRET_KEY=xxx` |
