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
