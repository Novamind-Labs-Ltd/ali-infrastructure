# -----------------------------------------------------------------------------
# Helm Addon Module - Variables
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Environment Context (Optional - for tagging/metadata)
# -----------------------------------------------------------------------------
variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, prod). Used for metadata."
  default     = null
}

# -----------------------------------------------------------------------------
# Kubernetes Configuration
# -----------------------------------------------------------------------------
variable "kubeconfig_path" {
  type        = string
  description = "Path to kubeconfig file used by the Helm provider."
}

# -----------------------------------------------------------------------------
# Chart Configuration
# -----------------------------------------------------------------------------
variable "release_name" {
  type        = string
  description = "Helm release name."
}

variable "chart_repository" {
  type        = string
  description = "Helm chart repository URL."
}

variable "chart_name" {
  type        = string
  description = "Helm chart name."
}

variable "chart_version" {
  type        = string
  description = "Helm chart version. If null, uses latest."
  default     = null
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace for the release."
}

variable "create_namespace" {
  type        = bool
  description = "Whether to create the namespace if it doesn't exist."
  default     = true
}

# -----------------------------------------------------------------------------
# Values Configuration
# -----------------------------------------------------------------------------
variable "values_file" {
  type        = string
  description = "Path to a YAML file containing Helm values."
  default     = null
}

variable "values_inline" {
  type        = string
  description = "Inline YAML string of Helm values. Merged after values_file."
  default     = null
}

variable "set_values" {
  type = list(object({
    name  = string
    value = string
    type  = optional(string)
  }))
  description = "Individual values to set. Takes precedence over values file."
  default     = []
}

variable "set_sensitive_values" {
  type = list(object({
    name  = string
    value = string
    type  = optional(string)
  }))
  description = "Sensitive values to set (not shown in logs)."
  default     = []
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Deployment Behavior
# -----------------------------------------------------------------------------
variable "timeout" {
  type        = number
  description = "Time in seconds to wait for release to complete."
  default     = 300
}

variable "atomic" {
  type        = bool
  description = "If true, roll back on failure."
  default     = false
}

variable "wait" {
  type        = bool
  description = "Wait for resources to be ready before marking release successful."
  default     = true
}

variable "wait_for_jobs" {
  type        = bool
  description = "Wait for all Jobs to complete before marking release successful."
  default     = false
}

variable "cleanup_on_fail" {
  type        = bool
  description = "Delete new resources on failed release."
  default     = false
}

variable "force_update" {
  type        = bool
  description = "Force resource update through delete/recreate if needed."
  default     = false
}

variable "recreate_pods" {
  type        = bool
  description = "Recreate pods during upgrade."
  default     = false
}

variable "max_history" {
  type        = number
  description = "Maximum number of release revisions to keep."
  default     = 10
}

variable "dependency_update" {
  type        = bool
  description = "Run helm dependency update before installing."
  default     = false
}

variable "skip_crds" {
  type        = bool
  description = "Skip CRD installation."
  default     = false
}

variable "render_subchart_notes" {
  type        = bool
  description = "Render subchart notes along with the parent."
  default     = true
}
