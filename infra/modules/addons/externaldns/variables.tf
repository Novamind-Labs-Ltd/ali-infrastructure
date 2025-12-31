variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, prod)."
}

variable "remote_state" {
  description = "Remote state backend placeholders sourced from bootstrap outputs."
  type = object({
    region              = string
    bucket              = string
    key                 = string
    profile             = string
    tablestore_table    = string
    tablestore_endpoint = string
  })
}

variable "kubeconfig_path" {
  type        = string
  description = "Path to kubeconfig used by the Helm provider."
}

variable "values_file" {
  type        = string
  description = "Path to the Helm values file for external-dns."
}

variable "namespace" {
  type        = string
  description = "Namespace for the external-dns release."
  default     = "external-dns"
}

variable "release_name" {
  type        = string
  description = "Helm release name for external-dns."
  default     = "externaldns"
}

variable "chart_name" {
  type        = string
  description = "Chart name for external-dns."
  default     = "external-dns"
}

variable "chart_repository" {
  type        = string
  description = "Chart repository for external-dns."
  default     = "https://kubernetes-sigs.github.io/external-dns/"
}

variable "chart_version" {
  type        = string
  description = "Chart version for external-dns."
  default     = null
}

variable "dns_zone" {
  type        = string
  description = "DNS zone managed by external-dns."
  default     = null
}
