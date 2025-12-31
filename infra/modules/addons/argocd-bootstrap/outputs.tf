locals {
  values_data = try(yamldecode(file(var.values_file)), {})
  status_data = try(local.values_data.status, {})
}

output "release_name" {
  description = "Helm release name for ArgoCD."
  value       = helm_release.argocd_bootstrap.name
}

output "release_namespace" {
  description = "Namespace for the ArgoCD release."
  value       = helm_release.argocd_bootstrap.namespace
}

output "release_status" {
  description = "Status of the ArgoCD Helm release."
  value       = helm_release.argocd_bootstrap.status
}

output "bootstrap_instructions" {
  description = "Instructions for bootstrapping ArgoCD applications."
  value = var.bootstrap_instructions != "" ? var.bootstrap_instructions : (
    try(local.status_data.bootstrap_instructions, "") != "" ? local.status_data.bootstrap_instructions : null
  )
}
