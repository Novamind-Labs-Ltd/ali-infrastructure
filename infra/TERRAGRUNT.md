# Terragrunt Infrastructure Guide

This document describes the Terragrunt-based infrastructure architecture and how to use it.

## Overview

The infrastructure uses [Terragrunt](https://terragrunt.gruntwork.io/) following Gruntwork best practices for:

- **DRY Configuration**: Eliminate duplication between environments
- **Automatic Backend**: Backend configuration is generated automatically
- **Dependency Management**: Explicit module dependencies with output passing
- **Consistent Providers**: Provider versions are consistent across all modules
- **Environment Isolation**: Separate state buckets for dev/prod
- **Validation Hooks**: Automatic validation before apply/plan

## Directory Structure

```
infra/
├── live/                       # Environment deployments
│   ├── root.hcl                # Root configuration (backend, hooks)
│   ├── dev/
│   │   ├── env.hcl             # Dev environment variables
│   │   ├── foundation-network/
│   │   │   └── terragrunt.hcl  # Self-contained config
│   │   ├── ack-cluster/
│   │   │   └── terragrunt.hcl
│   │   └── addons/
│   │       ├── ingress-nginx/
│   │       ├── cert-manager/
│   │       ├── externaldns/
│   │       └── argocd/
│   └── prod/
│       └── (same structure as dev)
├── modules/                    # Terraform modules
│   ├── foundation-network/
│   ├── ack-cluster/
│   └── helm-addon/
└── bootstrap/                  # One-time setup
    └── remote-state/
```

## Quick Start

### Prerequisites

1. Install Terragrunt:
   ```bash
   # macOS
   brew install terragrunt

   # Or download from https://terragrunt.gruntwork.io/docs/getting-started/install/
   ```

2. Ensure bootstrap has been run (remote state bucket exists)

3. Configure Alibaba Cloud credentials:
   ```bash
   # Dev environment
   aliyun configure --profile novamind-sandbox-kun

   # Prod environment (separate credentials)
   aliyun configure --profile novamind-prod
   ```

### Deploy an Environment

```bash
# Navigate to environment
cd infra/live/dev

# Deploy all modules in dependency order
terragrunt run-all apply

# Or deploy specific module
cd foundation-network
terragrunt apply
```

### Deploy Specific Module

```bash
# Deploy foundation network
cd infra/live/dev/foundation-network
terragrunt apply

# Deploy ACK cluster (automatically uses network outputs)
cd ../ack-cluster
terragrunt apply

# Deploy an addon
cd ../addons/ingress-nginx
terragrunt apply
```

### Plan Changes

```bash
# Plan all modules
cd infra/live/dev
terragrunt run-all plan

# Plan specific module
cd foundation-network
terragrunt plan
```

### Destroy Environment

```bash
# Destroy all modules (in reverse dependency order)
cd infra/live/dev
terragrunt run-all destroy

# Destroy specific module
cd ack-cluster
terragrunt destroy
```

## Configuration

### Environment Variables (`env.hcl`)

Each environment has an `env.hcl` file with all configuration:

```hcl
locals {
  environment = "dev"

  # Remote state (isolated per environment)
  remote_state_region = "ap-southeast-1"
  remote_state_bucket = "tfstate-sandbox"  # prod uses "tfstate-prod"
  # ... more config

  # Foundation network
  foundation_name_prefix = "ack-dev"
  foundation_vpc_cidr = "10.10.0.0/16"
  # ... more config

  # ACK cluster
  ack_name_prefix = "ack-dev"
  ack_kubernetes_version = "1.34.1-aliyun.1"
  # ... more config

  # Helm chart versions (pinned for reproducibility)
  ingress_nginx_chart_version = "4.10.1"
  cert_manager_chart_version  = "1.14.5"
}
```

### Environment Variable Overrides

Configuration can be overridden via environment variables (useful for CI/CD):

```bash
# Override state bucket
export TG_STATE_BUCKET=tfstate-prod

# Override Alibaba Cloud profile
export ALICLOUD_PROFILE=novamind-prod

# Override lock table endpoint
export TG_STATE_LOCK_ENDPOINT=https://tfstate-prod.ap-southeast-1.ots.aliyuncs.com
```

### Enabling Addons

Addons are disabled by default. Enable them in `env.hcl`:

```hcl
locals {
  # Enable ingress-nginx
  ingress_nginx_enabled = true

  # Enable cert-manager
  cert_manager_enabled = true
}
```

Then apply:

```bash
cd infra/live/dev
terragrunt run-all apply
```

### Module Dependencies

Dependencies are automatically managed:

```
foundation-network  →  ack-cluster  →  addons/*
```

When you run `terragrunt run-all apply`, modules are applied in the correct order.

## Production Environment

### Isolated State Storage

Production uses a separate state bucket for security:

```hcl
# live/prod/env.hcl
locals {
  remote_state_bucket              = "tfstate-prod"
  remote_state_profile             = "novamind-prod"
  remote_state_tablestore_endpoint = "https://tfstate-prod.ap-southeast-1.ots.aliyuncs.com"
}
```

To provision prod state infrastructure:
1. Create a new OSS bucket: `tfstate-prod`
2. Create a new TableStore instance: `tfstate-prod`
3. Create a new TableStore table: `terraform_state_lock`
4. Create a new Alibaba Cloud profile: `novamind-prod`

### Chart Version Pinning

Production requires explicit chart versions:

```hcl
# live/prod/env.hcl
locals {
  ingress_nginx_chart_version = "4.10.1"
  cert_manager_chart_version  = "1.14.5"
  externaldns_chart_version   = "1.14.4"
  argocd_chart_version        = "7.3.3"
}
```

## Validation Hooks

The infrastructure includes automatic validation hooks:

- **before_hook "validate"**: Runs `terraform validate` before plan/apply
- **before_hook "fmt_check"**: Checks formatting before plan/apply
- **after_hook "apply_success"**: Logs successful applies
- **error_hook "apply_error"**: Logs failures for debugging

## Best Practices

### 1. Always Plan First

```bash
terragrunt plan
# Review changes carefully
terragrunt apply
```

### 2. Use `run-all` Carefully

For production, prefer deploying modules individually:

```bash
# Instead of:
terragrunt run-all apply

# Do:
cd foundation-network && terragrunt apply
cd ../ack-cluster && terragrunt apply
```

### 3. Lock Versions in Production

Pin specific versions in `env.hcl`:

```hcl
locals {
  ack_kubernetes_version = "1.34.1-aliyun.1"  # Pinned
  ingress_nginx_chart_version = "4.10.1"      # Pinned
}
```

### 4. Review Generated Files

Terragrunt generates these files (gitignored):

- `backend.tf` - Backend configuration
- `provider_versions_override.tf` - Provider version constraints

Review them if debugging issues.

### 5. Use Environment Variables for CI/CD

Override configuration via environment variables:

```bash
export ALICLOUD_PROFILE=ci-runner
export TG_STATE_BUCKET=tfstate-ci
terragrunt apply
```

## Troubleshooting

### "Backend configuration changed"

Run:
```bash
terragrunt init -reconfigure
```

### "Module not found"

Ensure you're in the correct directory with a `terragrunt.hcl` file:
```bash
ls terragrunt.hcl
```

### "Dependency not applied"

Apply dependencies first:
```bash
cd ../foundation-network
terragrunt apply
cd ../ack-cluster
terragrunt apply
```

Or use:
```bash
terragrunt run-all apply --terragrunt-include-external-dependencies
```

### Viewing Terragrunt Debug Output

```bash
TERRAGRUNT_LOG_LEVEL=debug terragrunt plan
```

## Commands Reference

| Command | Description |
|---------|-------------|
| `terragrunt plan` | Plan changes for current module |
| `terragrunt apply` | Apply changes for current module |
| `terragrunt destroy` | Destroy current module |
| `terragrunt run-all plan` | Plan all modules in environment |
| `terragrunt run-all apply` | Apply all modules in order |
| `terragrunt run-all destroy` | Destroy all modules (reverse order) |
| `terragrunt output` | Show module outputs |
| `terragrunt validate` | Validate configuration |
| `terragrunt init` | Initialize module |

## Further Reading

- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
- [Terragrunt Quick Start](https://terragrunt.gruntwork.io/docs/getting-started/quick-start/)
- [Terragrunt CLI Reference](https://terragrunt.gruntwork.io/docs/reference/cli-options/)
- [Gruntwork Best Practices](https://terragrunt.gruntwork.io/docs/guides/terralith-to-terragrunt/)
