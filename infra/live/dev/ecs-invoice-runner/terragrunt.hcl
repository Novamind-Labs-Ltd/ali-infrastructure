# -----------------------------------------------------------------------------
# Dev - ECS Invoice Runner
# -----------------------------------------------------------------------------
# Standalone ECS instance for invoice processing workload.
# Uses the generic ecs-standalone module with workload-specific user_data.
#
# To enable:
#   1. Set ecs_invoice_runner_enabled = true in env.hcl
#   2. Set ecs_invoice_runner_ssh_key to your SSH public key
#   3. Set ecs_invoice_runner_ssh_cidr to your IP (e.g., "1.2.3.4/32")
#   4. Run: terragrunt apply
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

# terraform {
#   source = "${dirname(find_in_parent_folders("root.hcl"))}/../modules/ecs-standalone"
# }

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

# Note: Module requires ssh_public_key to be set in env.hcl before apply
# No dependencies - standalone module with isolated VPC

inputs = {
  name_prefix      = local.env.locals.ecs_invoice_runner_name
  instance_type    = local.env.locals.ecs_invoice_runner_type
  vpc_cidr         = local.env.locals.ecs_invoice_runner_vpc_cidr
  allowed_ssh_cidr = local.env.locals.ecs_invoice_runner_ssh_cidr
  ssh_public_key   = local.env.locals.ecs_invoice_runner_ssh_key
  budget_usd       = local.env.locals.ecs_invoice_runner_budget
  user_data_file   = "${get_terragrunt_dir()}/user_data.sh"
  tags             = local.env.locals.ecs_invoice_runner_tags
  zone_id          = local.env.locals.ecs_invoice_runner_zone_id
  image_id         = local.env.locals.ecs_invoice_runner_image_id
}
