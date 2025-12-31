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
