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
  description = "Path to the Helm values file for cert-manager."
}

variable "namespace" {
  type        = string
  description = "Namespace for the cert-manager release."
  default     = "cert-manager"
}

variable "release_name" {
  type        = string
  description = "Helm release name for cert-manager."
  default     = "cert-manager"
}

variable "chart_name" {
  type        = string
  description = "Chart name for cert-manager."
  default     = "cert-manager"
}

variable "chart_repository" {
  type        = string
  description = "Chart repository for cert-manager."
  default     = "https://charts.jetstack.io"
}

variable "chart_version" {
  type        = string
  description = "Chart version for cert-manager."
  default     = null
}

variable "issuer_name" {
  type        = string
  description = "Certificate issuer name created by cert-manager."
  default     = null
}
