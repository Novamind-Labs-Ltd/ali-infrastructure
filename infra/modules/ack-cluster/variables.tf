variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, prod)."
}

variable "name_prefix" {
  type        = string
  description = "Prefix used for ACK cluster and node pool naming."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID hosting the ACK cluster."
}

variable "vswitch_ids" {
  type        = list(string)
  description = "VSwitch IDs for the ACK control plane."
}

variable "node_pool_vswitch_ids" {
  type        = list(string)
  description = "VSwitch IDs for ACK worker node pools."
}

variable "node_pool_instance_types" {
  type        = list(string)
  description = "Instance types for ACK worker nodes."
}

variable "node_pool_desired_size" {
  type        = number
  description = "Desired node count for the default worker pool."
}

variable "kubeconfig_path" {
  type        = string
  description = "Path to write the ACK kubeconfig file for Helm add-ons."
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for the ACK cluster."
  default     = "1.28.0"
}

variable "cluster_spec" {
  type        = string
  description = "ACK cluster specification tier."
  default     = "ack.pro.small"
}

variable "service_cidr" {
  type        = string
  description = "Service CIDR for the ACK cluster."
  default     = "172.19.0.0/20"
}

variable "pod_cidr" {
  type        = string
  description = "Pod CIDR for the ACK cluster."
  default     = "172.20.0.0/16"
}

variable "node_pool_disk_size" {
  type        = number
  description = "System disk size (GB) for worker nodes."
  default     = 120
}

variable "node_pool_disk_category" {
  type        = string
  description = "System disk category for worker nodes."
  default     = "cloud_essd"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to ACK resources."
  default     = {}
}

variable "api_endpoint_override" {
  type        = string
  description = "Optional API endpoint override if provider attribute is unavailable."
  default     = null
}

variable "oidc_issuer_url_override" {
  type        = string
  description = "Optional OIDC issuer URL override if provider attribute is unavailable."
  default     = null
}
