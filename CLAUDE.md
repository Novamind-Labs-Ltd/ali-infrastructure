# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Terragrunt-based Infrastructure-as-Code for AliCloud (Alibaba Cloud). Provisions ACK (Alibaba Container Service for Kubernetes) clusters and supporting resources.

## Essential Commands

### Terragrunt Operations

```bash
# Always set credentials first
export ALICLOUD_PROFILE=StsProfile  # or your profile name
export ALICLOUD_REGION=ap-southeast-1

# Deploy specific module
cd infra/live/dev/foundation-network
terragrunt plan
terragrunt apply

# Deploy all modules in dependency order
cd infra/live/dev
terragrunt run-all plan
terragrunt run-all apply

# Destroy (reverse dependency order)
terragrunt run-all destroy
```

### Validation & Formatting

```bash
# Format all Terraform files
terraform fmt -recursive infra/

# Validate configuration
terragrunt validate

# Debug logging
TERRAGRUNT_LOG_LEVEL=debug terragrunt plan
```

### State Operations

```bash
# List resources in state
terragrunt state list

# Show specific resource
terragrunt state show <resource_address>

# Import existing resource
terragrunt import <resource_address> <resource_id>
```

## Architecture

### Three-Layer Structure

```
Bootstrap Layer     →  OSS bucket + TableStore (state backend)
        ↓
Foundation Layer    →  Reusable Terraform modules
        ↓
Environment Layer   →  Per-environment Terragrunt configs (dev, prod)
```

### Module Dependency Chain

```
foundation-network  →  ack-cluster  →  addons/*
(VPC, subnets, NAT)    (K8s cluster)   (ingress, certs, DNS, ArgoCD)
```

Terragrunt automatically applies modules in correct order via `dependency` blocks.

### Directory Structure

```
infra/
├── live/                          # Environment deployments
│   ├── root.hcl                   # Root config (backend, hooks, providers)
│   ├── dev/
│   │   ├── env.hcl                # All dev environment variables
│   │   ├── foundation-network/
│   │   │   └── terragrunt.hcl     # Self-contained module config
│   │   └── ack-cluster/
│   │       └── terragrunt.hcl
│   └── prod/                      # Mirrors dev structure
├── modules/                       # Terraform modules
│   ├── foundation-network/        # VPC, subnets, NAT, security groups
│   ├── ack-cluster/               # Managed Kubernetes
│   └── helm-addon/                # Generic Helm chart deployer
└── bootstrap/
    └── remote-state/              # One-time OSS + TableStore setup
```

## Key Configuration Files

| File | Purpose |
|------|---------|
| `infra/live/root.hcl` | Backend config (OSS), validation hooks, provider versions |
| `infra/live/{env}/env.hcl` | All environment variables (network CIDRs, K8s version, chart versions) |
| `infra/live/{env}/{module}/terragrunt.hcl` | Module source, dependencies, inputs |

## Environment Variables

Override `env.hcl` defaults via environment:

```bash
ALICLOUD_PROFILE=<profile>           # Auth profile
ALICLOUD_REGION=<region>             # Region override
TG_STATE_BUCKET=<bucket>             # State bucket
TG_STATE_LOCK_ENDPOINT=<endpoint>    # TableStore endpoint
```

## Authentication

### Check Current Identity

```bash
aliyun sts GetCallerIdentity --profile <profile-name>
```

### Create/Configure Profile

```bash
aliyun configure --profile <profile-name>
```

### Common Auth Errors

- `InvalidAccessKeyId`: Wrong access key or profile doesn't exist
- `SignatureDoesNotMatch`: Wrong secret key
- `Forbidden.RAM`: Missing permissions - check RAM policies
- `Authorization header is invalid`: Wrong profile or expired STS token

## Module Dependencies & Mock Outputs

When a dependency hasn't been applied yet, Terragrunt uses mock outputs for `init`, `validate`, `plan`:

```hcl
dependency "network" {
  config_path = "../foundation-network"

  mock_outputs = {
    vpc_id             = "vpc-mock-12345"
    private_subnet_ids = ["vsw-mock-1", "vsw-mock-2"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}
```

To run `apply`, the dependency must be applied first to populate real outputs.

## State Migration

When migrating state between backends or restructuring:

```bash
# Pull existing state
terraform state pull > old-state.json

# Push to new backend (after init)
terraform state push fixed-state.json

# Move resources within state
terraform state mv <old_address> <new_address>
```

## Terragrunt Best Practices

### Always Plan First
```bash
terragrunt plan
# Review changes carefully
terragrunt apply
```

### Use `run-all` Carefully
For production, prefer deploying modules individually:
```bash
# Instead of:
terragrunt run-all apply

# Do:
cd foundation-network && terragrunt apply
cd ../ack-cluster && terragrunt apply
```

### Pin Versions in Production
In `env.hcl`:
```hcl
locals {
  ack_kubernetes_version      = "1.34.1-aliyun.1"  # Pinned
  ingress_nginx_chart_version = "4.10.1"           # Pinned
}
```

### Use Environment Variables for CI/CD
```bash
export ALICLOUD_PROFILE=ci-runner
export TG_STATE_BUCKET=tfstate-ci
terragrunt apply
```

### Review Generated Files
Terragrunt generates these files (gitignored) - review when debugging:
- `backend.tf` - Backend configuration
- `provider_versions_override.tf` - Provider version constraints

### Dependency Order
When applying manually, follow the dependency chain:
1. `foundation-network` (VPC, subnets)
2. `ack-cluster` (requires network outputs)
3. `addons/*` (requires cluster outputs)

### Destroy in Reverse Order
```bash
# Destroy addons first, then cluster, then network
cd addons/ingress-nginx && terragrunt destroy
cd ../../ack-cluster && terragrunt destroy
cd ../foundation-network && terragrunt destroy
```

## Troubleshooting

### "Backend configuration changed"
```bash
terragrunt init -reconfigure
```

### "Dependency has no outputs"
Apply the dependency first, or add mock_outputs.

### "Module not found"
Ensure you're in a directory with `terragrunt.hcl`.

### View Generated Files
Terragrunt generates `backend.tf` and `provider_versions_override.tf` in `.terragrunt-cache/`. Check these when debugging.
