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
