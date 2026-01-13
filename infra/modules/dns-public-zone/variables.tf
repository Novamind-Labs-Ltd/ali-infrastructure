# -----------------------------------------------------------------------------
# DNS Public Zone Module - Variables
# -----------------------------------------------------------------------------

variable "domain_name" {
  description = "The domain name for the public DNS zone (e.g., example.com). Must be already registered."
  type        = string

  validation {
    # Validates domain format: labels separated by dots, each 1-63 chars, alphanumeric + hyphens
    # Supports: example.com, sub.example.com, api.dev.example.com
    condition     = can(regex("^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid domain (e.g., example.com, sub.example.com, api.dev.example.com)."
  }
}

variable "create_domain_group" {
  description = "Whether to create a new domain group for organizing zones"
  type        = bool
  default     = false
}

variable "domain_group_name" {
  description = "Name of the domain group (required if create_domain_group is true)"
  type        = string
  default     = null
}

variable "group_id" {
  description = "Existing domain group ID to associate the zone with. Ignored if create_domain_group is true."
  type        = string
  default     = null
}

variable "remark" {
  description = "Remarks/description for the domain zone"
  type        = string
  default     = null
}

variable "records" {
  description = "List of DNS records to create in the zone"
  type = list(object({
    key      = optional(string, null)     # Optional unique key (auto-generated as type-rr if not set)
    rr       = string                     # Host record: "@" for apex, "www", "api", "*" for wildcard
    type     = string                     # Record type: A, AAAA, CNAME, TXT, MX, NS, SRV
    value    = string                     # Record value: IP address, hostname, or text
    ttl      = optional(number, 600)      # TTL in seconds (600-86400 for free tier)
    priority = optional(number, 10)       # Priority for MX records (1-100)
    status   = optional(string, "ENABLE") # Record status: ENABLE or DISABLE
    remark   = optional(string, null)     # Record description
  }))
  default = []

  validation {
    condition = alltrue([
      for r in var.records : contains(["A", "AAAA", "CNAME", "TXT", "MX", "NS", "SRV", "CAA", "REDIRECT_URL", "FORWARD_URL"], r.type)
    ])
    error_message = "Record type must be one of: A, AAAA, CNAME, TXT, MX, NS, SRV, CAA, REDIRECT_URL, FORWARD_URL."
  }

  validation {
    # Note: AliCloud free tier minimum TTL is 600 seconds. Paid tiers allow lower values.
    # API accepts 1-86400, but free tier may reject TTL < 600 at apply time.
    condition = alltrue([
      for r in var.records : r.ttl >= 1 && r.ttl <= 86400
    ])
    error_message = "TTL must be between 1 and 86400 seconds. Note: Free tier minimum is 600."
  }

  validation {
    condition = alltrue([
      for r in var.records : r.type != "MX" || (r.priority >= 1 && r.priority <= 100)
    ])
    error_message = "MX record priority must be between 1 and 100."
  }
}

variable "tags" {
  description = "Tags to apply to the DNS zone for resource management and cost allocation"
  type        = map(string)
  default     = {}
}
