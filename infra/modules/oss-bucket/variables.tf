# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "environment" {
  type        = string
  description = "Environment name (e.g., dev, prod)."
}

variable "name_prefix" {
  type        = string
  description = "Prefix used for naming OSS bucket and related resources."
}

variable "region" {
  type        = string
  description = "Alibaba Cloud region for the bucket."
}

# -----------------------------------------------------------------------------
# Bucket Configuration
# -----------------------------------------------------------------------------

variable "acl" {
  type        = string
  description = "Bucket ACL. Valid values: private, public-read, public-read-write."
  default     = "private"

  validation {
    condition     = contains(["private", "public-read", "public-read-write"], var.acl)
    error_message = "acl must be one of: private, public-read, public-read-write."
  }
}

variable "storage_class" {
  type        = string
  description = "Storage class for the bucket."
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "IA", "Archive", "ColdArchive"], var.storage_class)
    error_message = "storage_class must be one of: Standard, IA, Archive, ColdArchive."
  }
}

variable "force_destroy" {
  type        = bool
  description = "Whether to force destroy the bucket even if it contains objects."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all supported resources."
  default     = {}
}

# -----------------------------------------------------------------------------
# CORS Configuration
# -----------------------------------------------------------------------------

variable "enable_cors" {
  type        = bool
  description = "Whether to enable CORS configuration."
  default     = true
}

variable "cors_allowed_methods" {
  type        = list(string)
  description = "Allowed HTTP methods for CORS."
  default     = ["GET", "HEAD"]
}

variable "cors_allowed_origins" {
  type        = list(string)
  description = "Allowed origins for CORS."
  default     = ["*"]
}

variable "cors_allowed_headers" {
  type        = list(string)
  description = "Allowed headers for CORS."
  default     = ["*"]
}

variable "cors_expose_headers" {
  type        = list(string)
  description = "Headers to expose in CORS responses."
  default     = []
}

variable "cors_max_age_seconds" {
  type        = number
  description = "Max age in seconds for CORS preflight cache."
  default     = 3600
}

# -----------------------------------------------------------------------------
# Lifecycle Rules
# -----------------------------------------------------------------------------

variable "lifecycle_rules" {
  type = list(object({
    id                       = string
    prefix                   = string
    enabled                  = bool
    expiration_days          = optional(number)
    transition_days          = optional(number)
    transition_storage_class = optional(string)
  }))
  description = "Lifecycle rules for the bucket."
  default     = []
}

# -----------------------------------------------------------------------------
# RAM User for Imgix
# -----------------------------------------------------------------------------

variable "create_ram_user" {
  type        = bool
  description = "Whether to create a RAM user for Imgix access."
  default     = true
}

variable "ram_user_name" {
  type        = string
  description = "Name for the RAM user."
  default     = "imgix-oss-reader"
}
