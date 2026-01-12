# -----------------------------------------------------------------------------
# Prod Environment Configuration
# -----------------------------------------------------------------------------
# This file contains all environment-specific variables for the prod environment.
# These values are automatically loaded by _common/*.hcl configurations.
#
# IMPORTANT: Production environment - changes require manual approval.
# -----------------------------------------------------------------------------

locals {
  # ---------------------------------------------------------------------------
  # Environment Identifier
  # ---------------------------------------------------------------------------
  environment = "prod"

  # ---------------------------------------------------------------------------
  # Remote State Configuration (ISOLATED FROM DEV)
  # ---------------------------------------------------------------------------
  # CRITICAL: Production uses isolated state storage for security.
  #
  # To provision prod state infrastructure:
  #   1. Create a new OSS bucket: tfstate-prod
  #   2. Create a new TableStore instance: tfstate-prod
  #   3. Create a new TableStore table: terraform_state_lock
  #   4. Create a new Alibaba Cloud profile: novamind-prod
  #   5. Update the values below
  #
  # Or override via environment variables in CI/CD:
  #   TG_STATE_BUCKET=tfstate-prod
  #   TG_STATE_LOCK_ENDPOINT=https://tfstate-prod.ap-southeast-1.ots.aliyuncs.com
  #   ALICLOUD_PROFILE=novamind-prod
  # ---------------------------------------------------------------------------
  remote_state_region              = "ap-southeast-1"
  remote_state_bucket              = "tfstate-prod"
  remote_state_profile             = "novamind-prod"
  remote_state_tablestore_table    = "terraform_state_lock"
  remote_state_tablestore_endpoint = "https://tfstate-prod.ap-southeast-1.ots.aliyuncs.com"

  # ---------------------------------------------------------------------------
  # Foundation Network Configuration
  # ---------------------------------------------------------------------------
  foundation_name_prefix          = "ack-prod"
  foundation_vpc_cidr             = "10.20.0.0/16"  # Different CIDR from dev
  foundation_public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]  # 3 AZs for HA
  foundation_private_subnet_cidrs = ["10.20.101.0/24", "10.20.102.0/24", "10.20.103.0/24"]
  foundation_zones                = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  foundation_tags                 = { environment = "prod", managed_by = "terragrunt" }
  nat_gateway_type                = "Enhanced"

  # ---------------------------------------------------------------------------
  # ACK Cluster Configuration
  # ---------------------------------------------------------------------------
  ack_name_prefix              = "ack-prod"
  ack_kubernetes_version       = "1.34.1-aliyun.1"
  ack_cluster_spec             = "ack.pro.small"  # Pro tier for production
  ack_service_cidr             = "172.21.0.0/20"  # Different from dev
  ack_pod_cidr                 = "172.22.0.0/16"
  ack_node_pool_instance_types = ["ecs.g6.xlarge", "ecs.g6.2xlarge"]  # Larger instances
  ack_node_pool_desired_size   = 3  # Minimum 3 nodes for HA
  ack_node_pool_disk_size      = 200  # Larger disks
  ack_node_pool_disk_category  = "cloud_essd"
  ack_tags                     = { environment = "prod", managed_by = "terragrunt" }
  ack_kubeconfig_path          = "kubeconfig-prod.yaml"

  # ---------------------------------------------------------------------------
  # Addon Configuration (for helm-addon modules)
  # ---------------------------------------------------------------------------
  # IMPORTANT: Pin chart versions in production for reproducibility
  # ---------------------------------------------------------------------------

  # Ingress NGINX
  ingress_nginx_enabled       = false  # Enable when ready
  ingress_nginx_namespace     = "ingress-nginx"
  ingress_nginx_chart_version = "4.10.1"

  # External DNS
  externaldns_enabled       = false
  externaldns_namespace     = "external-dns"
  externaldns_zone          = null  # e.g., "prod.example.com"
  externaldns_chart_version = "1.14.4"

  # Cert Manager
  cert_manager_enabled       = false
  cert_manager_namespace     = "cert-manager"
  cert_manager_chart_version = "1.14.5"

  # ArgoCD
  argocd_enabled       = false
  argocd_namespace     = "argocd"
  argocd_chart_version = "7.3.3"
}
