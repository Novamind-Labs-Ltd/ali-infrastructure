# Module: addons/ingress-nginx

Installs the ingress-nginx Helm chart into the ACK cluster.

## Inputs

- `environment`: Environment name (e.g., dev, prod).
- `kubeconfig_path`: Path to kubeconfig used by the Helm provider.
- `values_file`: Path to the Helm values file for ingress-nginx.
- `namespace`: Namespace for the release.
- `release_name`: Helm release name.
- `chart_name`: Chart name for ingress-nginx.
- `chart_repository`: Helm chart repository URL.
- `chart_version`: Helm chart version (optional).
- `ingress_hostname`: Ingress hostname assigned to the NGINX load balancer.

## Outputs

- `release_name`: Helm release name.
- `release_namespace`: Release namespace.
- `release_status`: Helm release status.
- `ingress_hostname`: Ingress hostname assigned to the NGINX load balancer.

## Example Usage

```hcl
module "addons_ingress_nginx" {
  source = "../../modules/addons/ingress-nginx"

  environment  = local.environment
  remote_state = local.remote_state

  kubeconfig_path = var.ack_kubeconfig_path
  values_file     = "${path.module}/values/ingress-nginx.yaml"
}
```

## Dependency Notes

- Requires a reachable ACK cluster and valid kubeconfig.
- Values should be managed per environment under `infra/envs/<env>/values/`.
