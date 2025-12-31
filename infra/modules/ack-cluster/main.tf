terraform {
  required_version = ">= 1.3"

  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.200.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4"
    }
  }
}

locals {
  vpc_id_suffix = substr(var.vpc_id, 0, 8)
}

resource "alicloud_cs_managed_kubernetes" "ack_cluster" {
  name         = "${var.name_prefix}-${var.environment}-${local.vpc_id_suffix}"
  version      = var.kubernetes_version
  cluster_spec = var.cluster_spec
  vswitch_ids  = var.vswitch_ids

  service_cidr = var.service_cidr
  pod_cidr     = var.pod_cidr

  enable_rrsa = true
  tags        = var.tags
}

resource "alicloud_cs_kubernetes_node_pool" "ack_node_pool" {
  cluster_id     = alicloud_cs_managed_kubernetes.ack_cluster.id
  node_pool_name = "${var.name_prefix}-default"

  vswitch_ids    = var.node_pool_vswitch_ids
  instance_types = var.node_pool_instance_types
  desired_size   = var.node_pool_desired_size

  system_disk_category = var.node_pool_disk_category
  system_disk_size     = var.node_pool_disk_size

  tags = var.tags
}
