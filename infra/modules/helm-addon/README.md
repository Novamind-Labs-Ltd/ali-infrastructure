# Helm Addon Module

A generic, reusable Terraform module for deploying Helm charts to Kubernetes clusters. This module consolidates the functionality of individual addon modules (ingress-nginx, cert-manager, externaldns, argocd-bootstrap) into a single DRY implementation.

## Features

- **Generic**: Deploy any Helm chart by specifying repository, chart name, and version
- **Flexible Values**: Support for values files, inline YAML, and individual set values
- **Sensitive Data**: Separate handling for sensitive values (secrets)
- **Full Control**: All standard Helm deployment options (atomic, wait, timeout, etc.)
- **Isolated Cache**: Per-release Helm cache to support parallel deployments

## Usage

### Basic Example

```hcl
module "ingress_nginx" {
  source = "../../modules/helm-addon"

  release_name     = "ingress-nginx"
  chart_repository = "https://kubernetes.github.io/ingress-nginx"
  chart_name       = "ingress-nginx"
  namespace        = "ingress-nginx"
  kubeconfig_path  = var.kubeconfig_path
}
```

### With Values File

```hcl
module "cert_manager" {
  source = "../../modules/helm-addon"

  release_name     = "cert-manager"
  chart_repository = "https://charts.jetstack.io"
  chart_name       = "cert-manager"
  chart_version    = "v1.14.0"
  namespace        = "cert-manager"
  kubeconfig_path  = var.kubeconfig_path
  values_file      = "${path.module}/values/cert-manager.yaml"
}
```

### With Inline Values and Set Values

```hcl
module "argocd" {
  source = "../../modules/helm-addon"

  release_name     = "argocd"
  chart_repository = "https://argoproj.github.io/argo-helm"
  chart_name       = "argo-cd"
  namespace        = "argocd"
  kubeconfig_path  = var.kubeconfig_path

  values_inline = yamlencode({
    server = {
      replicas = 2
    }
  })

  set_values = [
    {
      name  = "server.service.type"
      value = "LoadBalancer"
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| kubeconfig_path | Path to kubeconfig file | `string` | n/a | yes |
| release_name | Helm release name | `string` | n/a | yes |
| chart_repository | Helm chart repository URL | `string` | n/a | yes |
| chart_name | Helm chart name | `string` | n/a | yes |
| namespace | Kubernetes namespace | `string` | n/a | yes |
| chart_version | Chart version (null = latest) | `string` | `null` | no |
| create_namespace | Create namespace if missing | `bool` | `true` | no |
| values_file | Path to values YAML file | `string` | `null` | no |
| values_inline | Inline YAML values | `string` | `null` | no |
| set_values | Individual values to set | `list(object)` | `[]` | no |
| set_sensitive_values | Sensitive values | `list(object)` | `[]` | no |
| timeout | Timeout in seconds | `number` | `300` | no |
| atomic | Rollback on failure | `bool` | `false` | no |
| wait | Wait for ready | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| release_name | Name of the Helm release |
| release_namespace | Namespace of the release |
| release_status | Status of the release |
| release_version | Chart version deployed |
| release_revision | Revision number |
| release_app_version | App version from chart |

## Migrating from Individual Addon Modules

Replace individual module calls:

```hcl
# Before (individual modules)
module "addons_ingress_nginx" {
  source = "../../modules/addons/ingress-nginx"
  # ...
}

# After (generic helm-addon)
module "ingress_nginx" {
  source = "../../modules/helm-addon"

  release_name     = "ingress-nginx"
  chart_repository = "https://kubernetes.github.io/ingress-nginx"
  chart_name       = "ingress-nginx"
  namespace        = "ingress-nginx"
  kubeconfig_path  = var.kubeconfig_path
  values_file      = "${path.module}/values/ingress-nginx.yaml"
}
```

## Addon Presets

Common addon configurations:

### ingress-nginx
```hcl
release_name     = "ingress-nginx"
chart_repository = "https://kubernetes.github.io/ingress-nginx"
chart_name       = "ingress-nginx"
namespace        = "ingress-nginx"
```

### cert-manager
```hcl
release_name     = "cert-manager"
chart_repository = "https://charts.jetstack.io"
chart_name       = "cert-manager"
namespace        = "cert-manager"
```

### external-dns
```hcl
release_name     = "externaldns"
chart_repository = "https://kubernetes-sigs.github.io/external-dns/"
chart_name       = "external-dns"
namespace        = "external-dns"
```

### ArgoCD
```hcl
release_name     = "argocd"
chart_repository = "https://argoproj.github.io/argo-helm"
chart_name       = "argo-cd"
namespace        = "argocd"
```
