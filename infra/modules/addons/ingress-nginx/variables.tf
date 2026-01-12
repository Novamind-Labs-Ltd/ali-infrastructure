variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, prod)."
}

variable "kubeconfig_path" {
  type        = string
  description = "Path to kubeconfig used by the Helm provider."
}

variable "values_file" {
  type        = string
  description = "Path to the Helm values file for ingress-nginx."
}

variable "namespace" {
  type        = string
  description = "Namespace for the ingress-nginx release."
  default     = "ingress-nginx"
}

variable "release_name" {
  type        = string
  description = "Helm release name for ingress-nginx."
  default     = "ingress-nginx"
}

variable "chart_name" {
  type        = string
  description = "Chart name for ingress-nginx."
  default     = "ingress-nginx"
}

variable "chart_repository" {
  type        = string
  description = "Chart repository for ingress-nginx."
  default     = "https://kubernetes.github.io/ingress-nginx"
}

variable "chart_version" {
  type        = string
  description = "Chart version for ingress-nginx."
  default     = null
}

variable "ingress_hostname" {
  type        = string
  description = "Ingress hostname assigned to the NGINX load balancer."
  default     = null
}
