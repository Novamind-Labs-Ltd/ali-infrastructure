# ali-infrastructure

AliCloud-native Infrastructure as Code using **Terragrunt** to provision foundation networking, ACK (Alibaba Cloud Kubernetes) clusters, and core add-ons. It standardizes remote state, identity, and pipelines, then hands off to GitOps (ArgoCD) for app delivery.

## Highlights

- **Terragrunt-based**: DRY configuration, automatic backend, dependency management
- **Remote state**: OSS for state + TableStore for locking (auto-configured)
- **Layered modules**: Reusable Terraform modules composed via Terragrunt
- **Add-ons via Helm**: ingress-nginx, ExternalDNS, cert-manager, ArgoCD
- **CloudSSO for humans**: OIDC→RAM for CI; ACK workload identity ready
- **GitOps handoff**: ArgoCD "app of apps" ready via module

## Repository Structure

```
infra/
├── live/                       # Environment deployments (Terragrunt)
│   ├── root.hcl                # Root config (backend, hooks, providers)
│   ├── dev/
│   │   ├── env.hcl             # Dev environment variables
│   │   ├── foundation-network/ # VPC, subnets, NAT
│   │   ├── ack-cluster/        # Managed Kubernetes
│   │   ├── oss-imgix/          # OSS bucket for images
│   │   ├── ecs-invoice-runner/ # Standalone ECS for batch jobs
│   │   └── addons/             # Helm charts
│   │       ├── ingress-nginx/
│   │       ├── cert-manager/
│   │       ├── externaldns/
│   │       └── argocd/
│   └── prod/
│       └── (same structure)
├── modules/                    # Reusable Terraform modules
│   ├── foundation-network/
│   ├── ack-cluster/
│   ├── helm-addon/
│   ├── oss-bucket/
│   └── ecs-standalone/
└── bootstrap/
    └── remote-state/           # One-time OSS + TableStore setup

docs/                           # PRD, architecture, guidelines
```

## Prerequisites

- **Terraform** >= 1.5.0
- **Terragrunt** >= 0.50.0
- **Aliyun CLI** 3.0.271+
- **CloudSSO** access configured

## Quick Start

### 1. Authenticate via CloudSSO

```bash
aliyun configure --profile novamind-sandbox-kun
aliyun sts GetCallerIdentity -p novamind-sandbox-kun
```

### 2. Bootstrap Remote State (once)

```bash
cd infra/bootstrap/remote-state
terraform init
terraform apply
```

### 3. Deploy Environment

```bash
# Deploy all modules in dependency order
cd infra/live/dev
terragrunt run-all apply

# Or deploy specific module
cd infra/live/dev/foundation-network
terragrunt apply
```

### 4. Deploy Specific Modules

```bash
# Foundation network first
cd infra/live/dev/foundation-network
terragrunt apply

# Then ACK cluster
cd ../ack-cluster
terragrunt apply

# Then addons
cd ../addons/ingress-nginx
terragrunt apply
```

## Configuration

### Environment Variables (`env.hcl`)

Each environment has centralized configuration:

```hcl
# infra/live/dev/env.hcl
locals {
  environment = "dev"

  # Remote state
  remote_state_bucket  = "tfstate-sandbox"
  remote_state_profile = "novamind-sandbox-kun"

  # Foundation network
  foundation_vpc_cidr = "10.10.0.0/16"
  foundation_zones    = ["ap-southeast-1a", "ap-southeast-1b"]

  # ACK cluster
  ack_kubernetes_version = "1.34.1-aliyun.1"
  ack_cluster_spec       = "ack.standard"
}
```

### Override via Environment Variables

```bash
export ALICLOUD_PROFILE=novamind-prod
export TG_STATE_BUCKET=tfstate-prod
terragrunt apply
```

## Modules Overview

| Module | Description |
|--------|-------------|
| `foundation-network` | VPC, subnets, NAT gateway, security groups |
| `ack-cluster` | ACK managed Kubernetes + node pool + RRSA |
| `helm-addon` | Generic Helm chart deployment |
| `oss-bucket` | OSS bucket with optional RAM user for CDN integration |
| `ecs-standalone` | Isolated ECS instance with VPC (for batch jobs, dev VMs, etc.) |

## Commands Reference

| Command | Description |
|---------|-------------|
| `terragrunt plan` | Plan changes for current module |
| `terragrunt apply` | Apply changes for current module |
| `terragrunt destroy` | Destroy current module |
| `terragrunt run-all plan` | Plan all modules in environment |
| `terragrunt run-all apply` | Apply all modules in dependency order |
| `terragrunt run-all destroy` | Destroy all modules (reverse order) |

## Documentation

- **Terragrunt Guide**: `infra/TERRAGRUNT.md`
- **Auth Setup**: `infra/ALIYUN_AUTH.md`
- **Architecture**: `docs/architecture.md`
- **PRD**: `docs/prd.md`

## Troubleshooting

### Backend configuration changed

```bash
terragrunt init -reconfigure
```

### Dependency not applied

```bash
cd ../foundation-network && terragrunt apply
cd ../ack-cluster && terragrunt apply
```

### Debug output

```bash
TERRAGRUNT_LOG_LEVEL=debug terragrunt plan
```
