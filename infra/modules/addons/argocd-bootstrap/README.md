# Module: addons/argocd-bootstrap

Installs the ArgoCD Helm chart to bootstrap GitOps workflows on ACK.

## Inputs

- `environment`: Environment name (e.g., dev, prod).
- `kubeconfig_path`: Path to kubeconfig used by the Helm provider.
- `values_file`: Path to the Helm values file for ArgoCD.
- `namespace`: Namespace for the release.
- `release_name`: Helm release name.
- `chart_name`: Chart name for ArgoCD.
- `chart_repository`: Helm chart repository URL.
- `chart_version`: Helm chart version (optional).
- `bootstrap_instructions`: Instructions for bootstrapping ArgoCD applications.

## Outputs

- `release_name`: Helm release name.
- `release_namespace`: Release namespace.
- `release_status`: Helm release status.
- `bootstrap_instructions`: Instructions for bootstrapping ArgoCD applications.

## Example Usage

```hcl
module "addons_argocd_bootstrap" {
  source = "../../modules/addons/argocd-bootstrap"

  environment  = local.environment
  remote_state = local.remote_state

  kubeconfig_path = var.ack_kubeconfig_path
  values_file     = "${path.module}/values/argocd-bootstrap.yaml"
}
```

## Dependency Notes

- Requires a reachable ACK cluster and valid kubeconfig.
- Values should be managed per environment under `infra/envs/<env>/values/`.
