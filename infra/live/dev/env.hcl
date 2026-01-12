# -----------------------------------------------------------------------------
# Dev Environment Configuration
# -----------------------------------------------------------------------------
# This file contains all environment-specific variables for the dev environment.
# These values are automatically loaded by _common/*.hcl configurations.
#
# To customize for your environment:
#   1. Copy this file or edit values directly
#   2. Update remote_state_* values from bootstrap outputs
#   3. Adjust network CIDRs and zones as needed
# -----------------------------------------------------------------------------

locals {
  # ---------------------------------------------------------------------------
  # Environment Identifier
  # ---------------------------------------------------------------------------
  environment = "dev"

  # ---------------------------------------------------------------------------
  # Remote State Configuration
  # ---------------------------------------------------------------------------
  # These values come from the bootstrap module outputs.
  # Run: terraform -chdir=infra/bootstrap/remote-state output
  #
  # Can be overridden via environment variables:
  #   TG_STATE_BUCKET, TG_STATE_LOCK_ENDPOINT, ALICLOUD_PROFILE
  # ---------------------------------------------------------------------------
  remote_state_region              = "ap-southeast-1"
  remote_state_bucket              = "tfstate-sandbox"
  remote_state_profile             = "novamind-sandbox-kun"
  remote_state_tablestore_table    = "terraform_state_lock"
  remote_state_tablestore_endpoint = "https://tfstate-sandbox.ap-southeast-1.ots.aliyuncs.com"

  # ---------------------------------------------------------------------------
  # Foundation Network Configuration
  # ---------------------------------------------------------------------------
  foundation_name_prefix          = "ack-dev"
  foundation_vpc_cidr             = "10.10.0.0/16"
  foundation_public_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24"]
  foundation_private_subnet_cidrs = ["10.10.101.0/24", "10.10.102.0/24"]
  foundation_zones                = ["ap-southeast-1a", "ap-southeast-1b"]
  foundation_tags                 = { environment = "dev", managed_by = "terragrunt" }
  nat_gateway_type                = "Enhanced"

  # ---------------------------------------------------------------------------
  # ACK Cluster Configuration
  # ---------------------------------------------------------------------------
  ack_name_prefix              = "ack-dev"
  ack_kubernetes_version       = "1.34.1-aliyun.1"
  ack_cluster_spec             = "ack.standard"
  ack_service_cidr             = "172.19.0.0/20"
  ack_pod_cidr                 = "172.20.0.0/16"
  ack_node_pool_instance_types = ["ecs.g9i.xlarge"]
  ack_node_pool_desired_size   = 0
  ack_node_pool_disk_size      = 120
  ack_node_pool_disk_category  = "cloud_essd"
  ack_tags                     = { environment = "dev", managed_by = "terragrunt" }
  ack_kubeconfig_path          = "kubeconfig-dev.yaml"

  # ---------------------------------------------------------------------------
  # Addon Configuration (for helm-addon modules)
  # ---------------------------------------------------------------------------
  # Chart versions: Dev can use latest for testing, but pin for reproducibility
  # ---------------------------------------------------------------------------

  # Ingress NGINX
  ingress_nginx_enabled       = false  # Set to true when ready
  ingress_nginx_namespace     = "ingress-nginx"
  ingress_nginx_chart_version = "4.10.1"

  # External DNS
  externaldns_enabled       = false
  externaldns_namespace     = "external-dns"
  externaldns_zone          = null  # e.g., "dev.example.com"
  externaldns_chart_version = "1.14.4"

  # Cert Manager
  cert_manager_enabled       = false
  cert_manager_namespace     = "cert-manager"
  cert_manager_chart_version = "1.14.5"

  # ArgoCD
  argocd_enabled       = false
  argocd_namespace     = "argocd"
  argocd_chart_version = "7.3.3"

  # ---------------------------------------------------------------------------
  # OSS Imgix Configuration
  # ---------------------------------------------------------------------------
  # Bucket for image storage with Imgix CDN integration.
  # Primary: Private bucket with RAM user for S3-compatible access.
  # Fallback: Public-read bucket with Web Folder source.
  # ---------------------------------------------------------------------------
  oss_imgix_name_prefix     = "novamind"
  oss_imgix_acl             = "public-read"
  oss_imgix_force_destroy   = true  # Dev only - allows bucket deletion
  oss_imgix_cors_origins    = ["*"]
  oss_imgix_create_ram_user = false  # Imgix integration not possible, using OSS Image Processing instead
  oss_imgix_ram_user_name   = "imgix-oss-reader-dev"
  oss_imgix_tags            = { environment = "dev", managed_by = "terragrunt", purpose = "imgix-images" }
}
