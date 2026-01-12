# -----------------------------------------------------------------------------
# Dev - Foundation Network
# -----------------------------------------------------------------------------
# Deploys VPC, subnets, NAT gateway, and security groups for dev environment.
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../modules/foundation-network"
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  environment = local.env.locals.environment
  name_prefix = local.env.locals.foundation_name_prefix

  # Network configuration
  vpc_cidr             = local.env.locals.foundation_vpc_cidr
  public_subnet_cidrs  = local.env.locals.foundation_public_subnet_cidrs
  private_subnet_cidrs = local.env.locals.foundation_private_subnet_cidrs
  zones                = local.env.locals.foundation_zones
  nat_gateway_type     = try(local.env.locals.nat_gateway_type, "Enhanced")

  tags = try(local.env.locals.foundation_tags, { environment = local.env.locals.environment })
}
