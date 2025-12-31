# Module: addons/externaldns

Installs the external-dns Helm chart into the ACK cluster.

## Inputs

- `environment`: Environment name (e.g., dev, prod).
- `kubeconfig_path`: Path to kubeconfig used by the Helm provider.
- `values_file`: Path to the Helm values file for external-dns.
- `namespace`: Namespace for the release.
- `release_name`: Helm release name.
- `chart_name`: Chart name for external-dns.
- `chart_repository`: Helm chart repository URL.
- `chart_version`: Helm chart version (optional).
- `dns_zone`: DNS zone managed by external-dns.

## Outputs

- `release_name`: Helm release name.
- `release_namespace`: Release namespace.
- `release_status`: Helm release status.
- `dns_zone`: DNS zone managed by external-dns.

## Example Usage

```hcl
module "addons_externaldns" {
  source = "../../modules/addons/externaldns"

  environment  = local.environment
  remote_state = local.remote_state

  kubeconfig_path = var.ack_kubeconfig_path
  values_file     = "${path.module}/values/externaldns.yaml"
}
```

## Dependency Notes

- Requires a reachable ACK cluster and valid kubeconfig.
- Values should be managed per environment under `infra/envs/<env>/values/`.
