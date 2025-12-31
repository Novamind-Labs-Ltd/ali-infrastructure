# Module: ack-cluster

Provisions an AliCloud ACK managed Kubernetes cluster and a default node pool with RRSA (OIDC) enabled.

## Inputs

- `environment`: Environment name (e.g., dev, prod).
- `name_prefix`: Prefix used for cluster and node pool naming.
- `vpc_id`: VPC ID hosting the ACK cluster.
- `vswitch_ids`: VSwitch IDs for the ACK control plane.
- `node_pool_vswitch_ids`: VSwitch IDs for ACK worker nodes.
- `node_pool_instance_types`: Instance types for ACK worker nodes.
- `node_pool_desired_size`: Desired node count for the worker pool.
- `kubeconfig_path`: Path where the kubeconfig should be written for Helm add-ons.
- `kubernetes_version`: Kubernetes version for the cluster.
- `cluster_spec`: ACK cluster specification tier.
- `service_cidr`: Service CIDR for the cluster.
- `pod_cidr`: Pod CIDR for the cluster.
- `node_pool_disk_size`: System disk size (GB) for worker nodes.
- `node_pool_disk_category`: System disk category for worker nodes.
- `tags`: Tags applied to ACK resources.
- `api_endpoint_override`: Optional API endpoint override if provider attribute is unavailable.
- `oidc_issuer_url_override`: Optional OIDC issuer URL override if provider attribute is unavailable.

## Outputs

- `cluster_id`: ACK cluster ID.
- `cluster_name`: ACK cluster name.
- `api_endpoint`: ACK API server endpoint.
- `kubeconfig_raw`: Raw kubeconfig content for the ACK cluster.
- `kubeconfig_path`: Filesystem path where the kubeconfig should be written.
- `oidc_issuer_url`: OIDC issuer URL for workload identity.
- `node_pool_ids`: Node pool IDs.
- `connections_raw`: Raw connection info returned by the ACK cluster resource.

## Example Usage

```hcl
module "ack_cluster" {
  source = "../../modules/ack-cluster"

  environment  = local.environment
  remote_state = local.remote_state

  name_prefix              = var.ack_name_prefix
  vpc_id                   = module.foundation_network.vpc_id
  vswitch_ids              = module.foundation_network.private_subnet_ids
  node_pool_vswitch_ids    = module.foundation_network.private_subnet_ids
  node_pool_instance_types = var.ack_node_pool_instance_types
  node_pool_desired_size   = var.ack_node_pool_desired_size
  kubeconfig_path          = var.ack_kubeconfig_path
  kubernetes_version       = var.ack_kubernetes_version
  cluster_spec             = var.ack_cluster_spec
  service_cidr             = var.ack_service_cidr
  pod_cidr                 = var.ack_pod_cidr
  node_pool_disk_size      = var.ack_node_pool_disk_size
  node_pool_disk_category  = var.ack_node_pool_disk_category
  tags                     = var.ack_tags
}
```

## Dependency Notes

- Requires AliCloud provider configuration at the environment level.
- Expects VPC and subnet outputs from `foundation-network`.
- RRSA (OIDC) is enabled for future workload identity integration.

## Troubleshooting

- If cluster creation fails with `ErrorNotEnabled`, enable ACK Pro (cskpro) or switch to a non-Pro `cluster_spec` (e.g., `ack.standard`).
- If node pool creation fails with `AliyunOOSLifecycleHook4CSRole`, authorize that RAM role for the OOS service in the RAM console.
- If instance type errors mention zones/authorization, pick a type supported in your selected zones.
- If `api_endpoint`/`oidc_issuer_url` are null immediately after create, wait for cluster connections to populate or set overrides.
