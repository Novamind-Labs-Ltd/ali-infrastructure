# ECS Standalone Module

Creates an isolated ECS instance with its own VPC, vSwitch, and Security Group. Useful for batch jobs, dev VMs, or standalone workloads that don't need to be part of the main infrastructure.

## Features

- **Isolated network**: Creates its own VPC, vSwitch, and Security Group
- **SSH access**: Configurable CIDR whitelist for SSH
- **Cost control**: Auto-release time based on budget and hourly cost
- **Cloud-init**: Optional user_data script for instance initialization
- **Sensible defaults**: Ubuntu 22.04 LTS, cloud_essd disk

## Usage

### Via Terragrunt (Recommended)

```hcl
# terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../modules/ecs-standalone"
}

inputs = {
  name_prefix      = "my-workload"
  instance_type    = "ecs.c7.large"
  allowed_ssh_cidr = "1.2.3.4/32"  # Your IP
  ssh_public_key   = "ssh-rsa AAAA..."
  budget_usd       = 50
  user_data_file   = "${get_terragrunt_dir()}/user_data.sh"
  tags             = { environment = "dev", purpose = "batch-job" }
}
```

### Direct Terraform

```hcl
module "batch_job" {
  source = "../modules/ecs-standalone"

  name_prefix      = "batch-job"
  instance_type    = "ecs.c7.large"
  allowed_ssh_cidr = "1.2.3.4/32"
  ssh_public_key   = file("~/.ssh/id_rsa.pub")
  budget_usd       = 50

  tags = {
    environment = "dev"
    purpose     = "batch-processing"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name_prefix` | Prefix for all resource names | `string` | n/a | yes |
| `allowed_ssh_cidr` | CIDR allowed for SSH access | `string` | n/a | yes |
| `ssh_public_key` | SSH public key to inject | `string` | n/a | yes |
| `instance_type` | ECS instance type | `string` | `"ecs.c7.large"` | no |
| `image_id` | Optional image ID (defaults to Ubuntu 22.04) | `string` | `""` | no |
| `vpc_cidr` | VPC CIDR block | `string` | `"10.66.0.0/16"` | no |
| `vswitch_cidr` | vSwitch CIDR block | `string` | `"10.66.1.0/24"` | no |
| `internet_max_bandwidth_out` | Public bandwidth in Mbps (0 = no public IP) | `number` | `10` | no |
| `system_disk_category` | System disk type | `string` | `"cloud_essd"` | no |
| `system_disk_performance_level` | ESSD performance level | `string` | `"PL1"` | no |
| `user_data` | Cloud-init script content | `string` | `""` | no |
| `user_data_file` | Path to cloud-init script file | `string` | `""` | no |
| `budget_usd` | Budget cap for auto-release calculation | `number` | `100` | no |
| `estimated_hourly_cost_usd` | Estimated hourly cost | `number` | `0.20` | no |
| `auto_release_hours` | Max hours before auto-release | `number` | `72` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `instance_id` | ECS instance ID |
| `public_ip` | Public IP address |
| `private_ip` | Private IP address |
| `ssh_command` | SSH connection command |
| `auto_release_time` | Planned auto-release time (UTC) |
| `vpc_id` | VPC ID |
| `vswitch_id` | vSwitch ID |
| `security_group_id` | Security Group ID |
| `key_pair_name` | SSH Key Pair name |

## Cost Control

The module calculates auto-release time based on:
- `budget_usd`: Maximum budget in USD
- `estimated_hourly_cost_usd`: Conservative hourly cost estimate
- `auto_release_hours`: Hard cap on runtime

```
effective_hours = min(auto_release_hours, floor(budget_usd / estimated_hourly_cost_usd))
```

Example: With `budget_usd = 100` and `estimated_hourly_cost_usd = 0.20`:
- Budget allows: 500 hours
- Capped by `auto_release_hours = 72`
- Instance auto-releases after 72 hours

## Security Notes

1. **SSH CIDR**: Always restrict `allowed_ssh_cidr` to your IP (`x.x.x.x/32`) in production
2. **Auto-release**: The instance will be automatically terminated at `auto_release_time`
3. **Public IP**: Set `internet_max_bandwidth_out = 0` to disable public IP
