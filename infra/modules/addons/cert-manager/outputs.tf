locals {
  values_data = try(yamldecode(file(var.values_file)), {})
  status_data = try(local.values_data.status, {})
}

output "release_name" {
  description = "Helm release name for cert-manager."
  value       = helm_release.cert_manager.name
}

output "release_namespace" {
  description = "Namespace for the cert-manager release."
  value       = helm_release.cert_manager.namespace
}

output "release_status" {
  description = "Status of the cert-manager Helm release."
  value       = helm_release.cert_manager.status
}

output "issuer_name" {
  description = "Certificate issuer name created by cert-manager."
  value = var.issuer_name != "" ? var.issuer_name : (
    try(local.status_data.issuer_name, "") != "" ? local.status_data.issuer_name : null
  )
}
