# -----------------------------------------------------------------------------
# DNS Public Zone Module - Outputs
# -----------------------------------------------------------------------------

output "domain_id" {
  description = "The ID of the DNS domain"
  value       = alicloud_alidns_domain.this.domain_id
}

output "domain_name" {
  description = "The domain name"
  value       = alicloud_alidns_domain.this.domain_name
}

output "dns_servers" {
  description = "List of AliCloud DNS nameservers for NS delegation at your registrar"
  value       = alicloud_alidns_domain.this.dns_servers
}

output "puny_code" {
  description = "Punycode representation for internationalized domain names"
  value       = alicloud_alidns_domain.this.puny_code
}

output "group_id" {
  description = "The domain group ID (from created group or existing group_id input)"
  value       = alicloud_alidns_domain.this.group_id
}

output "group_name" {
  description = "The domain group name"
  value       = alicloud_alidns_domain.this.group_name
}

output "domain_group_id" {
  description = "The ID of the created domain group (null if not created)"
  value       = var.create_domain_group ? alicloud_alidns_domain_group.this[0].id : null
}

output "record_ids" {
  description = "Map of record keys (type-rr) to their IDs"
  value       = { for k, r in alicloud_alidns_record.this : k => r.id }
}

output "records" {
  description = "Map of created DNS records with their details"
  value = {
    for k, r in alicloud_alidns_record.this : k => {
      id          = r.id
      domain_name = r.domain_name
      rr          = r.rr
      type        = r.type
      value       = r.value
      ttl         = r.ttl
      priority    = r.priority
      status      = r.status
    }
  }
}
