# Module: foundation-network

Reusable AliCloud networking primitives for ACK environments, including VPC, public/private subnets, NAT gateway, and base security group.

## Requirements

- Terraform >= 1.3
- AliCloud provider >= 1.200.0

## Inputs

| Name                 | Description                                                                    | Type         | Required | Default    |
| -------------------- | ------------------------------------------------------------------------------ | ------------ | -------- | ---------- |
| environment          | Environment name (e.g., dev, prod).                                            | string       | yes      | n/a        |
| remote_state         | Remote state backend placeholders sourced from bootstrap outputs.              | object       | yes      | n/a        |
| name_prefix          | Prefix used for naming network resources.                                      | string       | yes      | n/a        |
| vpc_cidr             | CIDR block for the VPC.                                                        | string       | yes      | n/a        |
| public_subnet_cidrs  | CIDR blocks for public subnets (one per zone).                                 | list(string) | yes      | n/a        |
| private_subnet_cidrs | CIDR blocks for private subnets (one per zone).                                | list(string) | yes      | n/a        |
| zones                | Availability zones for the subnets, aligned by index to the subnet CIDR lists. | list(string) | yes      | n/a        |
| tags                 | Tags applied to all supported resources.                                       | map(string)  | no       | `{}`       |
| nat_gateway_spec     | NAT gateway specification size (Standard NAT only).                            | string       | no       | `Small`    |
| nat_gateway_type     | NAT gateway type (Standard or Enhanced).                                       | string       | no       | `Enhanced` |
| nat_bandwidth_mbps   | EIP bandwidth for the NAT gateway.                                             | number       | no       | `5`        |

## Outputs

| Name                 | Description                                       |
| -------------------- | ------------------------------------------------- |
| vpc_id               | ID of the VPC.                                    |
| vpc_name             | Name of the VPC.                                  |
| public_subnet_ids    | IDs of the public subnets.                        |
| public_subnet_names  | Names of the public subnets.                      |
| private_subnet_ids   | IDs of the private subnets.                       |
| private_subnet_names | Names of the private subnets.                     |
| nat_gateway_id       | ID of the NAT gateway.                            |
| nat_gateway_name     | Name of the NAT gateway.                          |
| security_group_ids   | IDs of the security groups created for the VPC.   |
| security_group_names | Names of the security groups created for the VPC. |

## Example Usage

```hcl
module "foundation_network" {
  source = "../../modules/foundation-network"

  environment  = local.environment
  remote_state = local.remote_state

  name_prefix           = "ack-dev"
  vpc_cidr              = "10.10.0.0/16"
  public_subnet_cidrs   = ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnet_cidrs  = ["10.10.101.0/24", "10.10.102.0/24"]
  zones                 = ["ap-southeast-1a", "ap-southeast-1b"]
  tags                  = { environment = "dev" }
  nat_gateway_spec      = "Small"
  nat_bandwidth_mbps    = 5
}
```

## Dependency Notes

- Provider configuration (region/profile) is expected in the calling stack; this module does not configure providers.
- The NAT gateway is attached to the first public subnet; ensure public/private subnet lists align with the zones list.
- Security group rules are intentionally minimal; add rules in downstream modules as needed.
