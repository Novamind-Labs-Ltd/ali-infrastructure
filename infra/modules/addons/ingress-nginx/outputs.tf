locals {
  values_data = try(yamldecode(file(var.values_file)), {})
  status_data = try(local.values_data.status, {})
}

output "release_name" {
  description = "Helm release name for ingress-nginx."
  value       = helm_release.ingress_nginx.name
}

output "release_namespace" {
  description = "Namespace for the ingress-nginx release."
  value       = helm_release.ingress_nginx.namespace
}

output "release_status" {
  description = "Status of the ingress-nginx Helm release."
  value       = helm_release.ingress_nginx.status
}

output "ingress_hostname" {
  description = "Ingress hostname assigned to the NGINX load balancer."
  value = var.ingress_hostname != "" ? var.ingress_hostname : (
    try(local.status_data.ingress_hostname, "") != "" ? local.status_data.ingress_hostname : null
  )
}
