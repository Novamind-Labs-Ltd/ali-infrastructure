# -----------------------------------------------------------------------------
# DNS Public Zone Module
# -----------------------------------------------------------------------------
# Creates an AliCloud DNS public zone with optional domain group and DNS records.
# Outputs NS servers for delegation at your domain registrar.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.3"

  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.200.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Domain Group (Optional)
# -----------------------------------------------------------------------------
# Create a domain group to organize multiple DNS zones together.
# Only created if create_domain_group = true.
# -----------------------------------------------------------------------------

resource "alicloud_alidns_domain_group" "this" {
  count             = var.create_domain_group ? 1 : 0
  domain_group_name = var.domain_group_name
}

# -----------------------------------------------------------------------------
# Public DNS Zone
# -----------------------------------------------------------------------------
# The main DNS zone resource. Domain must be registered and not already
# added by another Alibaba Cloud account.
# -----------------------------------------------------------------------------

resource "alicloud_alidns_domain" "this" {
  domain_name = var.domain_name
  group_id    = var.create_domain_group ? alicloud_alidns_domain_group.this[0].id : var.group_id
  remark      = var.remark
  tags        = var.tags
}

# -----------------------------------------------------------------------------
# DNS Records (Optional)
# -----------------------------------------------------------------------------
# Create DNS records within the zone. Supports A, AAAA, CNAME, TXT, MX, NS, SRV.
# Records are created using for_each for idempotent management.
# -----------------------------------------------------------------------------

resource "alicloud_alidns_record" "this" {
  # Use explicit key if provided, otherwise auto-generate from type-rr
  # Explicit keys are needed for round-robin DNS (multiple A records for same subdomain)
  for_each = { for r in var.records : coalesce(r.key, "${r.type}-${r.rr}") => r }

  domain_name = alicloud_alidns_domain.this.domain_name
  rr          = each.value.rr
  type        = each.value.type
  value       = each.value.value
  ttl         = each.value.ttl
  priority    = each.value.type == "MX" ? each.value.priority : null
  status      = each.value.status
  remark      = each.value.remark
}
