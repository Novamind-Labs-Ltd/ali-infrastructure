# -----------------------------------------------------------------------------
# Helm Addon Module
# -----------------------------------------------------------------------------
# A generic, reusable module for deploying Helm charts to Kubernetes.
# This consolidates the functionality of ingress-nginx, cert-manager,
# externaldns, and argocd-bootstrap into a single DRY module.
#
# Usage:
#   module "ingress_nginx" {
#     source = "../../modules/helm-addon"
#
#     release_name     = "ingress-nginx"
#     chart_repository = "https://kubernetes.github.io/ingress-nginx"
#     chart_name       = "ingress-nginx"
#     namespace        = "ingress-nginx"
#     values_file      = "./values/ingress-nginx.yaml"
#     kubeconfig_path  = var.kubeconfig_path
#   }
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.3"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9"
    }
  }
}

# -----------------------------------------------------------------------------
# Helm Provider Configuration
# -----------------------------------------------------------------------------
provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }

  # Use module-local cache to avoid conflicts between parallel deployments
  repository_config_path = "${path.module}/.helm-repositories-${var.release_name}.yaml"
  repository_cache       = "${path.module}/.helm-cache-${var.release_name}"
}

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------
locals {
  # Load values from file if provided, otherwise use empty list
  values_content = var.values_file != null && var.values_file != "" ? [file(var.values_file)] : []

  # Merge with any inline values provided
  all_values = var.values_inline != null ? concat(local.values_content, [var.values_inline]) : local.values_content
}

# -----------------------------------------------------------------------------
# Helm Release
# -----------------------------------------------------------------------------
resource "helm_release" "addon" {
  name             = var.release_name
  repository       = var.chart_repository
  chart            = var.chart_name
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = var.create_namespace

  # Deployment configuration
  timeout               = var.timeout
  atomic                = var.atomic
  wait                  = var.wait
  wait_for_jobs         = var.wait_for_jobs
  cleanup_on_fail       = var.cleanup_on_fail
  force_update          = var.force_update
  recreate_pods         = var.recreate_pods
  max_history           = var.max_history
  dependency_update     = var.dependency_update
  skip_crds             = var.skip_crds
  render_subchart_notes = var.render_subchart_notes

  # Values
  values = local.all_values

  # Dynamic set blocks for individual value overrides
  dynamic "set" {
    for_each = var.set_values
    content {
      name  = set.value.name
      value = set.value.value
      type  = try(set.value.type, null)
    }
  }

  # Dynamic set_sensitive blocks for sensitive values
  dynamic "set_sensitive" {
    for_each = var.set_sensitive_values
    content {
      name  = set_sensitive.value.name
      value = set_sensitive.value.value
      type  = try(set_sensitive.value.type, null)
    }
  }
}
