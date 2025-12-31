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
  description = "Path to the Helm values file for ArgoCD bootstrap."
}

variable "namespace" {
  type        = string
  description = "Namespace for the ArgoCD release."
  default     = "argocd"
}

variable "release_name" {
  type        = string
  description = "Helm release name for ArgoCD."
  default     = "argocd-bootstrap"
}

variable "chart_name" {
  type        = string
  description = "Chart name for ArgoCD."
  default     = "argo-cd"
}

variable "chart_repository" {
  type        = string
  description = "Chart repository for ArgoCD."
  default     = "https://argoproj.github.io/argo-helm"
}

variable "chart_version" {
  type        = string
  description = "Chart version for ArgoCD."
  default     = null
}

variable "bootstrap_instructions" {
  type        = string
  description = "Instructions for bootstrapping ArgoCD applications."
  default     = null
}
