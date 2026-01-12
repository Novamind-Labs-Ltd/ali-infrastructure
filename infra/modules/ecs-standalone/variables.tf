# -----------------------------------------------------------------------------
# ECS Standalone Module - Variables
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix for all resource names (e.g., 'invoice-runner', 'batch-job')"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed for SSH access. MUST be set (e.g., your IP/32 or 0.0.0.0/0)"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key to inject into the instance"
  type        = string
}

# -----------------------------------------------------------------------------
# Instance Configuration
# -----------------------------------------------------------------------------

variable "instance_type" {
  description = "ECS instance type"
  type        = string
  default     = "ecs.c7.large"
}

variable "image_id" {
  description = "Optional image ID. Defaults to latest Ubuntu 22.04 x86_64"
  type        = string
  default     = ""
}

variable "internet_max_bandwidth_out" {
  description = "Public bandwidth in Mbps (0 = no public IP)"
  type        = number
  default     = 10
}

variable "system_disk_category" {
  description = "System disk type (cloud_essd, cloud_ssd, cloud_efficiency)"
  type        = string
  default     = "cloud_essd"
}

variable "system_disk_performance_level" {
  description = "ESSD performance level (PL0, PL1, PL2, PL3)"
  type        = string
  default     = "PL1"
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.66.0.0/16"
}

variable "vswitch_cidr" {
  description = "vSwitch CIDR block"
  type        = string
  default     = "10.66.1.0/24"
}

variable "zone_id" {
  description = "Availability zone ID. If empty, auto-selects based on instance type."
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Cloud-Init (user_data)
# -----------------------------------------------------------------------------

variable "user_data" {
  description = "Cloud-init script content (mutually exclusive with user_data_file)"
  type        = string
  default     = ""
}

variable "user_data_file" {
  description = "Path to cloud-init script file (mutually exclusive with user_data)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Cost Control
# -----------------------------------------------------------------------------

variable "budget_usd" {
  description = "Budget cap in USD for auto-release calculation"
  type        = number
  default     = 100
}

variable "estimated_hourly_cost_usd" {
  description = "Estimated hourly cost for the instance (conservative)"
  type        = number
  default     = 0.20
}

variable "auto_release_hours" {
  description = "Max hours before auto-release (capped by budget)"
  type        = number
  default     = 72
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
