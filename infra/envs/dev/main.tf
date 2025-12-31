terraform {
  required_version = ">= 1.3"

  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.200.0"
    }
  }
}

provider "alicloud" {
  region  = var.remote_state_region
  profile = var.remote_state_profile
}

locals {
  environment = "dev"
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

  name_prefix          = var.foundation_name_prefix
  vpc_cidr             = var.foundation_vpc_cidr
  public_subnet_cidrs  = var.foundation_public_subnet_cidrs
  private_subnet_cidrs = var.foundation_private_subnet_cidrs
  zones                = var.foundation_zones
  tags                 = var.foundation_tags
  nat_gateway_type     = var.nat_gateway_type
}

module "ack_cluster" {
  source = "../../modules/ack-cluster"

  environment  = local.environment
  remote_state = local.remote_state

  name_prefix = var.ack_name_prefix
  vpc_id      = module.foundation_network.vpc_id
  vswitch_ids = module.foundation_network.private_subnet_ids

  node_pool_vswitch_ids    = module.foundation_network.private_subnet_ids
  node_pool_instance_types = var.ack_node_pool_instance_types
  node_pool_desired_size   = var.ack_node_pool_desired_size
  kubeconfig_path          = var.ack_kubeconfig_path

  kubernetes_version      = var.ack_kubernetes_version
  cluster_spec            = var.ack_cluster_spec
  service_cidr            = var.ack_service_cidr
  pod_cidr                = var.ack_pod_cidr
  node_pool_disk_size     = var.ack_node_pool_disk_size
  node_pool_disk_category = var.ack_node_pool_disk_category

  tags = var.ack_tags
}

// Helm addon modules intentionally disabled for initial ACK cluster bring-up.
// Uncomment when ready to install ingress-nginx, external-dns, cert-manager, and ArgoCD.
// module "addons_ingress_nginx" {
//   source = "../../modules/addons/ingress-nginx"
//
//   environment  = local.environment
//   remote_state = local.remote_state
//
//   kubeconfig_path  = var.ack_kubeconfig_path
//   values_file      = "${path.module}/values/ingress-nginx.yaml"
//   ingress_hostname = var.ingress_hostname
// }
//
// module "addons_externaldns" {
//   source = "../../modules/addons/externaldns"
//
//   environment  = local.environment
//   remote_state = local.remote_state
//
//   kubeconfig_path = var.ack_kubeconfig_path
//   values_file     = "${path.module}/values/externaldns.yaml"
//   dns_zone        = var.externaldns_zone
// }
//
// module "addons_cert_manager" {
//   source = "../../modules/addons/cert-manager"
//
//   environment  = local.environment
//   remote_state = local.remote_state
//
//   kubeconfig_path = var.ack_kubeconfig_path
//   values_file     = "${path.module}/values/cert-manager.yaml"
//   issuer_name     = var.cert_manager_issuer_name
// }
//
// module "addons_argocd_bootstrap" {
//   source = "../../modules/addons/argocd-bootstrap"
//
//   environment  = local.environment
//   remote_state = local.remote_state
//
//   kubeconfig_path        = var.ack_kubeconfig_path
//   values_file            = "${path.module}/values/argocd-bootstrap.yaml"
//   bootstrap_instructions = var.argocd_bootstrap_instructions
// }
