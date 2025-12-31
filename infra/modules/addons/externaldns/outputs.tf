locals {
  values_data = try(yamldecode(file(var.values_file)), {})
  status_data = try(local.values_data.status, {})
}

output "release_name" {
  description = "Helm release name for external-dns."
  value       = helm_release.externaldns.name
}

output "release_namespace" {
  description = "Namespace for the external-dns release."
  value       = helm_release.externaldns.namespace
}

output "release_status" {
  description = "Status of the external-dns Helm release."
  value       = helm_release.externaldns.status
}

output "dns_zone" {
  description = "DNS zone managed by external-dns."
  value = var.dns_zone != "" ? var.dns_zone : (
    try(local.status_data.dns_zone, "") != "" ? local.status_data.dns_zone : null
  )
}
