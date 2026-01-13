# -----------------------------------------------------------------------------
# Dev - Ingress NGINX
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

skip = !local.env.locals.ingress_nginx_enabled

inputs = {
  environment      = local.env.locals.environment
  release_name     = "ingress-nginx"
  chart_repository = "https://kubernetes.github.io/ingress-nginx"
  chart_name       = "ingress-nginx"
  chart_version    = try(local.env.locals.ingress_nginx_chart_version, null)
  namespace        = local.env.locals.ingress_nginx_namespace
  kubeconfig_path  = local.env.locals.ack_kubeconfig_path
  values_file      = "${get_terragrunt_dir()}/values.yaml"
}
