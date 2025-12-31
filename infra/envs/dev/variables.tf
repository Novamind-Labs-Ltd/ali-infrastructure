variable "remote_state_region" {
  type        = string
  description = "Region for the OSS backend (from the bootstrap module outputs)."
}

variable "remote_state_bucket" {
  type        = string
  description = "OSS bucket name from the bootstrap module output remote_state_bucket."
}

variable "remote_state_key" {
  type        = string
  description = "State file key/path for this environment."
}

variable "remote_state_profile" {
  type        = string
  description = "AliCloud profile name used for the backend configuration."
}

variable "remote_state_tablestore_table" {
  type        = string
  description = "TableStore lock table name from the bootstrap module output lock_table_name."
}

variable "remote_state_tablestore_endpoint" {
  type        = string
  description = "TableStore endpoint from the bootstrap module output tablestore_endpoint."
}

variable "foundation_name_prefix" {
  type        = string
  description = "Name prefix for foundation-network resources."
}

variable "foundation_vpc_cidr" {
  type        = string
  description = "VPC CIDR for foundation-network."
}

variable "foundation_public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs for foundation-network."
}

variable "foundation_private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs for foundation-network."
}

variable "foundation_zones" {
  type        = list(string)
  description = "Zones aligned with subnet CIDR lists."
}

variable "foundation_tags" {
  type        = map(string)
  description = "Tags for foundation-network resources."
  default     = {}
}

variable "nat_gateway_type" {
  type        = string
  description = "NAT gateway type (Standard or Enhanced)."
  default     = "Enhanced"
}

variable "ack_name_prefix" {
  type        = string
  description = "Name prefix for ACK cluster resources."
}

variable "ack_kubernetes_version" {
  type        = string
  description = "Kubernetes version for the ACK cluster."
  default     = "1.34.1-aliyun.1"
}

variable "ack_cluster_spec" {
  type        = string
  description = "ACK cluster specification tier."
  default     = "ack.standard"
}

variable "ack_service_cidr" {
  type        = string
  description = "Service CIDR for the ACK cluster."
  default     = "172.19.0.0/20"
}

variable "ack_pod_cidr" {
  type        = string
  description = "Pod CIDR for the ACK cluster."
  default     = "172.20.0.0/16"
}

variable "ack_node_pool_instance_types" {
  type        = list(string)
  description = "Instance types for ACK worker nodes."
}

variable "ack_node_pool_desired_size" {
  type        = number
  description = "Desired node count for ACK worker nodes."
}

variable "ack_node_pool_disk_size" {
  type        = number
  description = "System disk size (GB) for ACK worker nodes."
  default     = 120
}

variable "ack_node_pool_disk_category" {
  type        = string
  description = "System disk category for ACK worker nodes."
  default     = "cloud_essd"
}

variable "ack_tags" {
  type        = map(string)
  description = "Tags applied to ACK resources."
  default     = {}
}

variable "ack_kubeconfig_path" {
  type        = string
  description = "Path to the kubeconfig file used by Helm add-ons."
}

variable "ingress_hostname" {
  type        = string
  description = "Ingress hostname assigned to the NGINX load balancer."
  default     = null
}

variable "externaldns_zone" {
  type        = string
  description = "DNS zone managed by external-dns."
  default     = null
}

variable "cert_manager_issuer_name" {
  type        = string
  description = "Certificate issuer name created by cert-manager."
  default     = null
}

variable "argocd_bootstrap_instructions" {
  type        = string
  description = "Instructions for bootstrapping ArgoCD applications."
  default     = null
}
