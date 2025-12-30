terraform {
  required_version = ">= 1.3"
}

locals {
  environment = "prod"
  remote_state = {
    region              = var.remote_state_region
    bucket              = var.remote_state_bucket
    key                 = var.remote_state_key
    profile             = var.remote_state_profile
    tablestore_table    = var.remote_state_tablestore_table
    tablestore_endpoint = var.remote_state_tablestore_endpoint
  }
}

module "foundation_network" {
  source = "../../modules/foundation-network"

  environment  = local.environment
  remote_state = local.remote_state

  # TODO: Wire additional inputs for the prod environment.
}

module "ack_cluster" {
  source = "../../modules/ack-cluster"

  environment  = local.environment
  remote_state = local.remote_state

  # TODO: Wire additional inputs for the prod environment.
}

module "addons_ingress_nginx" {
  source = "../../modules/addons/ingress-nginx"

  environment  = local.environment
  remote_state = local.remote_state

  # TODO: Wire additional inputs for the prod environment.
}

module "addons_externaldns" {
  source = "../../modules/addons/externaldns"

  environment  = local.environment
  remote_state = local.remote_state

  # TODO: Wire additional inputs for the prod environment.
}

module "addons_cert_manager" {
  source = "../../modules/addons/cert-manager"

  environment  = local.environment
  remote_state = local.remote_state

  # TODO: Wire additional inputs for the prod environment.
}

module "addons_argocd_bootstrap" {
  source = "../../modules/addons/argocd-bootstrap"

  environment  = local.environment
  remote_state = local.remote_state

  # TODO: Wire additional inputs for the prod environment.
}
