# Module: addons/cert-manager

Installs the cert-manager Helm chart into the ACK cluster.

## Inputs

- `environment`: Environment name (e.g., dev, prod).
- `kubeconfig_path`: Path to kubeconfig used by the Helm provider.
- `values_file`: Path to the Helm values file for cert-manager.
- `namespace`: Namespace for the release.
- `release_name`: Helm release name.
- `chart_name`: Chart name for cert-manager.
- `chart_repository`: Helm chart repository URL.
- `chart_version`: Helm chart version (optional).
- `issuer_name`: Certificate issuer name created by cert-manager.

## Outputs

- `release_name`: Helm release name.
- `release_namespace`: Release namespace.
- `release_status`: Helm release status.
- `issuer_name`: Certificate issuer name created by cert-manager.

## Example Usage

```hcl
module "addons_cert_manager" {
  source = "../../modules/addons/cert-manager"

  environment  = local.environment
  remote_state = local.remote_state

  kubeconfig_path = var.ack_kubeconfig_path
  values_file     = "${path.module}/values/cert-manager.yaml"
}
```

## Dependency Notes

- Requires a reachable ACK cluster and valid kubeconfig.
- Values should be managed per environment under `infra/envs/<env>/values/`.
