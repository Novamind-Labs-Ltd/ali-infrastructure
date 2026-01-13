# Story 0.2: Public Zone DNS Module

Status: review

## Story

As a **DevOps Engineer**,
I want **a Terraform module that provisions AliCloud DNS public zones with optional DNS records**,
so that **domains can be centrally managed via Infrastructure-as-Code and integrated with ExternalDNS for Kubernetes workloads**.

## Acceptance Criteria

1. **AC1:** Terraform module creates an AliCloud DNS public zone (`alicloud_alidns_domain`) for a specified domain
2. **AC2:** Module supports optional domain group association for organizing multiple zones
3. **AC3:** Module supports creating initial DNS records (A, CNAME, TXT, MX) via variable input
4. **AC4:** Module outputs zone ID, domain name, and DNS servers for NS delegation
5. **AC5:** Terragrunt configuration follows existing project patterns (env.hcl variables, terragrunt.hcl)
6. **AC6:** Module is reusable for prod deployment with environment-specific variables
7. **AC7:** Module supports tagging for resource management and cost allocation
8. **AC8:** Documentation includes NS delegation instructions for domain registrar

## Tasks / Subtasks

- [x] **Task 1: Create `dns-public-zone` Terraform module** (AC: 1, 2, 4, 7)
  - [x] 1.1 Create `infra/modules/dns-public-zone/main.tf` with `alicloud_alidns_domain` resource
  - [x] 1.2 Create `infra/modules/dns-public-zone/variables.tf` with configurable inputs
  - [x] 1.3 Create `infra/modules/dns-public-zone/outputs.tf` exposing zone details and NS servers
  - [x] 1.4 Create `infra/modules/dns-public-zone/README.md` with usage documentation
  - [x] 1.5 Add optional `alicloud_alidns_domain_group` for zone organization
  - [x] 1.6 Configure tags for all resources

- [x] **Task 2: Add DNS record management** (AC: 3)
  - [x] 2.1 Create `alicloud_alidns_record` resources using `for_each` over records variable
  - [x] 2.2 Support record types: A, AAAA, CNAME, TXT, MX, NS
  - [x] 2.3 Add TTL configuration per record (default: 600)
  - [x] 2.4 Add priority support for MX records

- [x] **Task 3: Create Terragrunt configuration for dev** (AC: 5, 6)
  - [x] 3.1 Create `infra/live/dev/dns-public-zone/terragrunt.hcl`
  - [x] 3.2 Add DNS configuration variables to `infra/live/dev/env.hcl`
  - [x] 3.3 Configure as standalone module (no VPC dependency)

- [x] **Task 4: Documentation and NS delegation** (AC: 8)
  - [x] 4.1 Document AliCloud DNS nameservers in README
  - [x] 4.2 Add example registrar NS delegation instructions
  - [x] 4.3 Document ExternalDNS integration pattern

- [x] **Task 5: Testing & Validation** (AC: 1-8)
  - [x] 5.1 Run `terraform fmt` and `terraform validate`
  - [ ] 5.2 Run `terragrunt plan` to verify configuration (REQUIRES CREDENTIALS)
  - [ ] 5.3 Run `terragrunt apply` in dev environment (REQUIRES CREDENTIALS)
  - [ ] 5.4 Verify NS records at domain registrar (POST-DEPLOY)
  - [ ] 5.5 Test DNS resolution with `dig` or `nslookup` (POST-DEPLOY)

## Dev Notes

### Architecture Patterns (from existing modules)

Following the established Terragrunt patterns in this project:

```
infra/
├── modules/
│   └── dns-public-zone/        # NEW: DNS zone management
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
└── live/
    ├── dev/
    │   ├── env.hcl             # Add dns_* variables
    │   └── dns-public-zone/    # NEW: Dev DNS zone
    │       └── terragrunt.hcl
    └── prod/
        └── dns-public-zone/    # FUTURE: Prod DNS zone
            └── terragrunt.hcl
```

### Naming Convention

Follow existing pattern from foundation-network and oss-bucket modules.

### AliCloud DNS Resources

**Primary Resources:**
- `alicloud_alidns_domain` - Creates a public DNS zone
- `alicloud_alidns_record` - Creates DNS records within the zone
- `alicloud_alidns_domain_group` - Optional grouping for multiple zones

**Provider Version:** `alicloud >= 1.200.0` (consistent with foundation-network)

---

### Module Implementation Pattern

**Key Resource Attributes (from AliCloud Terraform Provider v1.267.0):**

| Resource | Key Attributes | Notes |
|----------|---------------|-------|
| `alicloud_alidns_domain` | `domain_name`, `group_id`, `tags`, `remark` | Available since v1.95.0 |
| `alicloud_alidns_domain_group` | `domain_group_name` | Available since v1.84.0 |
| `alicloud_alidns_record` | `domain_name`, `rr`, `type`, `value`, `ttl`, `priority`, `status` | Available since v1.85.0 |

**Important:** The `alicloud_alidns_record` uses `rr` (not `host_record`) for the subdomain part.

```hcl
# main.tf
terraform {
  required_version = ">= 1.3"

  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.200.0"
    }
  }
}

# Optional domain group for organizing zones
resource "alicloud_alidns_domain_group" "this" {
  count             = var.create_domain_group ? 1 : 0
  domain_group_name = var.domain_group_name
}

# Public DNS zone
resource "alicloud_alidns_domain" "this" {
  domain_name = var.domain_name
  group_id    = var.create_domain_group ? alicloud_alidns_domain_group.this[0].id : var.group_id
  remark      = var.remark
  tags        = var.tags
}

# DNS records (optional)
# Note: Use "rr" for host record (e.g., "@", "www", "api")
resource "alicloud_alidns_record" "this" {
  for_each = { for r in var.records : "${r.type}-${r.rr}" => r }

  domain_name = alicloud_alidns_domain.this.domain_name
  rr          = each.value.rr           # e.g., "@", "www", "api", "alimail"
  type        = each.value.type         # A, AAAA, CNAME, TXT, MX, NS, SRV
  value       = each.value.value        # IP address or target hostname
  ttl         = lookup(each.value, "ttl", 600)
  priority    = each.value.type == "MX" ? lookup(each.value, "priority", 10) : null
  status      = lookup(each.value, "status", "ENABLE")
  remark      = lookup(each.value, "remark", null)
}
```

### Variables Pattern

```hcl
# variables.tf
variable "domain_name" {
  description = "The domain name for the public DNS zone (e.g., example.com)"
  type        = string
}

variable "create_domain_group" {
  description = "Whether to create a new domain group"
  type        = bool
  default     = false
}

variable "domain_group_name" {
  description = "Name of the domain group (required if create_domain_group is true)"
  type        = string
  default     = null
}

variable "group_id" {
  description = "Existing domain group ID to associate the zone with"
  type        = string
  default     = null
}

variable "remark" {
  description = "Remarks/description for the domain"
  type        = string
  default     = null
}

variable "records" {
  description = "List of DNS records to create"
  type = list(object({
    rr       = string                    # "@" for apex, "www", "api", etc.
    type     = string                    # A, AAAA, CNAME, TXT, MX, NS, SRV
    value    = string                    # Target IP or hostname
    ttl      = optional(number, 600)     # TTL in seconds (600-86400 for free tier)
    priority = optional(number, 10)      # For MX records (1-10)
    status   = optional(string, "ENABLE") # ENABLE or DISABLE
    remark   = optional(string)          # Record description
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to the DNS zone"
  type        = map(string)
  default     = {}
}
```

### Outputs Pattern

```hcl
# outputs.tf
output "domain_id" {
  description = "The ID of the DNS domain"
  value       = alicloud_alidns_domain.this.domain_id
}

output "domain_name" {
  description = "The domain name"
  value       = alicloud_alidns_domain.this.domain_name
}

output "dns_servers" {
  description = "List of AliCloud DNS nameservers for NS delegation"
  value       = alicloud_alidns_domain.this.dns_servers
}

output "group_id" {
  description = "The domain group ID"
  value       = alicloud_alidns_domain.this.group_id
}

output "record_ids" {
  description = "Map of record keys to their IDs"
  value       = { for k, r in alicloud_alidns_record.this : k => r.id }
}
```

### env.hcl Variables to Add

```hcl
# ---------------------------------------------------------------------------
# DNS Public Zone Configuration
# ---------------------------------------------------------------------------
# Public DNS zone for domain management.
# After apply, update NS records at your domain registrar.
# ---------------------------------------------------------------------------
dns_domain_name         = "example.com"  # Replace with your domain
dns_create_domain_group = true
dns_domain_group_name   = "novamind-zones-dev"
dns_initial_records     = [
  # Example: Verification TXT record
  # { host_record = "@", type = "TXT", value = "v=spf1 -all", ttl = 3600 },
]
dns_tags = { environment = "dev", managed_by = "terragrunt", purpose = "dns-zone" }
```

### Terragrunt Configuration Pattern

```hcl
# infra/live/dev/dns-public-zone/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl")).locals
}

terraform {
  source = "${get_repo_root()}/infra/modules/dns-public-zone"
}

inputs = {
  domain_name         = local.env.dns_domain_name
  create_domain_group = local.env.dns_create_domain_group
  domain_group_name   = local.env.dns_domain_group_name
  records             = local.env.dns_initial_records
  tags                = local.env.dns_tags
}
```

### NS Delegation Instructions

After applying the module, you'll receive AliCloud DNS nameservers in the output. Update your domain registrar's NS records:

**AliCloud DNS Nameservers (typical):**
```
ns1.alidns.com
ns2.alidns.com
```

**At your registrar (e.g., GoDaddy, Namecheap, Cloudflare):**
1. Navigate to DNS/Nameserver settings
2. Change to "Custom nameservers"
3. Enter AliCloud nameservers from Terraform output
4. Save and wait for propagation (up to 48 hours)

**Verify propagation:**
```bash
dig NS example.com +short
# Should return ns1.alidns.com and ns2.alidns.com
```

### ExternalDNS Integration

This module creates the DNS zone. ExternalDNS (already configured as addon) will manage records for Kubernetes Ingress/Service resources automatically.

**Integration flow:**
1. `dns-public-zone` module creates zone for `example.com`
2. ExternalDNS watches Ingress resources with `external-dns.alpha.kubernetes.io/hostname` annotation
3. ExternalDNS creates/updates A/CNAME records in the zone

**ExternalDNS configuration (in externaldns values):**
```yaml
provider: alibabacloud
alibabacloud:
  regionId: ap-southeast-1
  zoneType: public
domainFilters:
  - example.com  # Must match dns_domain_name
```

### Project Structure Notes

- **Module Location:** `infra/modules/dns-public-zone/` - standalone, no VPC dependency
- **Live Config:** `infra/live/dev/dns-public-zone/` - follows existing pattern
- **No ACK Dependency:** This module is independent of Kubernetes cluster
- **Provider Version:** `alicloud >= 1.200.0` (consistent with foundation-network)

### Security Considerations

- **No sensitive data:** DNS zones don't contain secrets
- **DNSSEC:** Consider enabling DNSSEC for production (out of scope for initial implementation)
- **Rate Limiting:** AliCloud DNS has API rate limits - batch record changes
- **Access Control:** RAM policies control who can modify DNS zones

### References

- [AliCloud DNS Terraform Provider - alicloud_alidns_domain](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/alidns_domain)
- [AliCloud DNS Terraform Provider - alicloud_alidns_record](https://registry.terraform.io/providers/aliyun/alicloud/latest/docs/resources/alidns_record)
- [AliCloud DNS Documentation](https://www.alibabacloud.com/help/en/dns)
- [Source: infra/live/dev/env.hcl - existing variable patterns]
- [Source: infra/modules/foundation-network/ - module structure pattern]
- [Source: infra/modules/oss-bucket/ - standalone module pattern]

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5 (Dev Agent)

### Debug Log References

- `terraform fmt` - Fixed formatting in variables.tf
- `terraform validate` - Passed successfully
- `terragrunt init` - Requires AliCloud credentials (expected)

### Completion Notes List

- Created complete `dns-public-zone` Terraform module following existing project patterns
- Module includes: `alicloud_alidns_domain`, `alicloud_alidns_domain_group`, `alicloud_alidns_record`
- Used provider version `alicloud >= 1.200.0` consistent with foundation-network module
- Variables include comprehensive validation for domain names, record types, TTL, and MX priority
- Outputs include `dns_servers` for NS delegation at registrar
- README includes complete NS delegation instructions for major registrars (GoDaddy, Namecheap, Cloudflare, Route 53)
- README includes ExternalDNS integration pattern for Kubernetes workloads
- Terragrunt config follows existing patterns with env.hcl variable references
- Tasks 5.2-5.5 require user credentials and deployment (marked as post-deploy verification)

### Change Log

| Date       | Change                                                              | Author              |
| ---------- | ------------------------------------------------------------------- | ------------------- |
| 2026-01-13 | Story created                                                       | SM Agent (Bob)      |
| 2026-01-13 | Implementation complete: Tasks 1-4 done, Task 5.1 passed validation | Dev Agent (Claude)  |
| 2026-01-13 | Code review: APPROVED with 4 minor fixes applied                    | AI Code Review      |

### File List

**Created:**

- `infra/modules/dns-public-zone/main.tf` - DNS zone, domain group, and record resources
- `infra/modules/dns-public-zone/variables.tf` - Module inputs with validations
- `infra/modules/dns-public-zone/outputs.tf` - Zone details, NS servers, record IDs
- `infra/modules/dns-public-zone/README.md` - Comprehensive usage and NS delegation docs
- `infra/live/dev/dns-public-zone/terragrunt.hcl` - Dev environment Terragrunt config

**Modified:**

- `infra/live/dev/env.hcl` - Added `dns_*` configuration variables
