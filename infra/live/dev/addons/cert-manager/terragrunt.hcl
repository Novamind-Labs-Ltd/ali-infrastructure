# -----------------------------------------------------------------------------
# Dev - Cert Manager
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/../modules/helm-addon"
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

dependency "ack" {
  config_path = "../../ack-cluster"

  mock_outputs = {
    cluster_id   = "cluster-mock-12345678"
    api_endpoint = "https://mock-api.kubernetes.local:6443"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

skip = !local.env.locals.cert_manager_enabled

inputs = {
  environment      = local.env.locals.environment
  release_name     = "cert-manager"
  chart_repository = "https://charts.jetstack.io"
  chart_name       = "cert-manager"
  chart_version    = try(local.env.locals.cert_manager_chart_version, null)
  namespace        = local.env.locals.cert_manager_namespace
  kubeconfig_path  = local.env.locals.ack_kubeconfig_path
  values_file      = "${get_terragrunt_dir()}/values.yaml"
}
