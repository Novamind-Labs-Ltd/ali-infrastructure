locals {
  primary_connection = alicloud_cs_managed_kubernetes.ack_cluster.connections
}

output "cluster_id" {
  description = "ACK cluster ID."
  value       = alicloud_cs_managed_kubernetes.ack_cluster.id
}

output "cluster_name" {
  description = "ACK cluster name."
  value       = alicloud_cs_managed_kubernetes.ack_cluster.name
}

output "api_endpoint" {
  description = "ACK API server endpoint (internet)."
  value = var.api_endpoint_override != null && var.api_endpoint_override != "" ? var.api_endpoint_override : (
    lookup(local.primary_connection, "api_server_endpoint", "") != "" ? lookup(local.primary_connection, "api_server_endpoint", "") : (
      lookup(local.primary_connection, "master_url", "") != "" ? lookup(local.primary_connection, "master_url", "") : (
        lookup(local.primary_connection, "master_endpoint", "") != "" ? lookup(local.primary_connection, "master_endpoint", "") : (
          lookup(local.primary_connection, "endpoint", "") != "" ? lookup(local.primary_connection, "endpoint", "") : null
        )
      )
    )
  )
}

output "kubeconfig_raw" {
  description = "Raw kubeconfig content for the ACK cluster."
  value       = alicloud_cs_managed_kubernetes.ack_cluster.kube_config
  sensitive   = true
}

output "kubeconfig_path" {
  description = "Filesystem path where the ACK kubeconfig is written."
  value       = var.kubeconfig_path
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for ACK workload identity."
  value = var.oidc_issuer_url_override != null && var.oidc_issuer_url_override != "" ? var.oidc_issuer_url_override : (
    lookup(local.primary_connection, "oidc_issuer_url", "") != "" ? lookup(local.primary_connection, "oidc_issuer_url", "") : (
      lookup(local.primary_connection, "rrsa_oidc_issuer_url", "") != "" ? lookup(local.primary_connection, "rrsa_oidc_issuer_url", "") : null
    )
  )
}

output "connections_raw" {
  description = "Raw connection info returned by the ACK cluster resource."
  value       = alicloud_cs_managed_kubernetes.ack_cluster.connections
}

output "node_pool_ids" {
  description = "IDs of ACK node pools."
  value       = [alicloud_cs_kubernetes_node_pool.ack_node_pool.id]
}
