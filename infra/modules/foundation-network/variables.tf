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

variable "name_prefix" {
  type        = string
  description = "Prefix used for naming network resources."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets (one per zone)."

  validation {
    condition     = length(var.public_subnet_cidrs) > 0
    error_message = "public_subnet_cidrs must contain at least one CIDR."
  }
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets (one per zone)."

  validation {
    condition     = length(var.private_subnet_cidrs) > 0
    error_message = "private_subnet_cidrs must contain at least one CIDR."
  }
}

variable "zones" {
  type        = list(string)
  description = "Availability zones for the subnets, aligned by index to the subnet CIDR lists."

  validation {
    condition     = length(var.zones) > 0
    error_message = "zones must contain at least one zone."
  }

  validation {
    condition     = length(var.zones) == length(var.public_subnet_cidrs)
    error_message = "zones length must match public_subnet_cidrs length."
  }

  validation {
    condition     = length(var.zones) == length(var.private_subnet_cidrs)
    error_message = "zones length must match private_subnet_cidrs length."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all supported resources."
  default     = {}
}

variable "nat_gateway_spec" {
  type        = string
  description = "NAT gateway specification size (Standard NAT only)."
  default     = "Small"
}

variable "nat_gateway_type" {
  type        = string
  description = "NAT gateway type (Standard or Enhanced)."
  default     = "Enhanced"
}

variable "nat_bandwidth_mbps" {
  type        = number
  description = "EIP bandwidth for the NAT gateway."
  default     = 5
}
