# -----------------------------------------------------------------------------
# Prod - ACK Cluster
# -----------------------------------------------------------------------------
# PRODUCTION: Changes require manual approval.
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../modules/ack-cluster"
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "network" {
  config_path = "../foundation-network"

  mock_outputs = {
    vpc_id             = "vpc-mock-12345678"
    private_subnet_ids = ["vsw-mock-1", "vsw-mock-2", "vsw-mock-3"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

inputs = {
  environment = local.env.locals.environment
  name_prefix = local.env.locals.ack_name_prefix

  # Network from dependency
  vpc_id                = dependency.network.outputs.vpc_id
  vswitch_ids           = dependency.network.outputs.private_subnet_ids
  node_pool_vswitch_ids = dependency.network.outputs.private_subnet_ids

  # Cluster configuration
  kubernetes_version = local.env.locals.ack_kubernetes_version
  cluster_spec       = local.env.locals.ack_cluster_spec
  service_cidr       = local.env.locals.ack_service_cidr
  pod_cidr           = local.env.locals.ack_pod_cidr

  # Node pool
  node_pool_instance_types = local.env.locals.ack_node_pool_instance_types
  node_pool_desired_size   = local.env.locals.ack_node_pool_desired_size
  node_pool_disk_size      = local.env.locals.ack_node_pool_disk_size
  node_pool_disk_category  = local.env.locals.ack_node_pool_disk_category

  kubeconfig_path = local.env.locals.ack_kubeconfig_path
  tags            = local.env.locals.ack_tags
}
