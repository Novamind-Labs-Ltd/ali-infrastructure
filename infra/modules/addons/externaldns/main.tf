terraform {
  required_version = ">= 1.3"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9"
    }
  }
}

provider "helm" {
  kubernetes = {
    config_path = var.kubeconfig_path
  }
  repository_config_path = "${path.module}/.helm-repositories.yaml"
  repository_cache       = "${path.module}/.helm-cache"
}

resource "helm_release" "externaldns" {
  name             = var.release_name
  repository       = var.chart_repository
  chart            = var.chart_name
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  values = [file(var.values_file)]
}
