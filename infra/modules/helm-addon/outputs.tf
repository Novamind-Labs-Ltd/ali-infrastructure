# -----------------------------------------------------------------------------
# Helm Addon Module - Outputs
# -----------------------------------------------------------------------------

output "release_name" {
  description = "The name of the Helm release."
  value       = helm_release.addon.name
}

output "release_namespace" {
  description = "The namespace of the Helm release."
  value       = helm_release.addon.namespace
}

output "release_status" {
  description = "Status of the Helm release."
  value       = helm_release.addon.status
}

output "release_version" {
  description = "The version of the chart deployed."
  value       = helm_release.addon.version
}

output "release_revision" {
  description = "The revision number of the release."
  value       = helm_release.addon.metadata[0].revision
}

output "release_chart" {
  description = "The chart name that was deployed."
  value       = helm_release.addon.metadata[0].chart
}

output "release_app_version" {
  description = "The app version of the chart."
  value       = helm_release.addon.metadata[0].app_version
}

output "release_values" {
  description = "The computed values used for this release."
  value       = helm_release.addon.metadata[0].values
  sensitive   = true
}
