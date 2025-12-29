variable "region" {
  description = "AliCloud region where state resources are created."
  type        = string
}

variable "profile" {
  description = "AliCloud CLI profile used for CloudSSO auth during bootstrap."
  type        = string
  default     = "CloudSSOProfile"
}

variable "bucket_name" {
  description = "Unique OSS bucket name (kebab-case) that will store Terraform state."
  type        = string
}

variable "table_store_instance_name" {
  description = "Name for the TableStore instance that backs Terraform state locking."
  type        = string
}

variable "lock_table_name" {
  description = "TableStore table that stores Terraform state locks."
  type        = string
  default     = "terraform_state_lock"
}

variable "table_store_description" {
  description = "Description metadata applied to the TableStore instance."
  type        = string
  default     = "Remote state lock instance"
}

variable "table_store_instance_type" {
  description = "TableStore instance billing mode (HighPerformance works across all regions)."
  type        = string
  default     = "HighPerformance"
}

variable "table_store_access_mode" {
  description = "Network access scope for TableStore. Use Vpc if private endpoints are configured."
  type        = string
  default     = "Any"
}

variable "tags" {
  description = "Map of tags applied to all managed resources."
  type        = map(string)
  default     = {}
}
