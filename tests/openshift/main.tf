#

terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "3.1.1"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "3.0.1"
    }
  }
}

provider "kubernetes" {
  config_path    = pathexpand("~/.kube/config")
  config_context = var.config_context
}

provider "helm" {
  kubernetes = {
    config_path    = pathexpand("~/.kube/config")
    config_context = var.config_context
  }
}

module "grafana" {
  source                      = "../../redis/openshift/modules/grafana"
}

module "redis_env" {
  source                      = "../../redis/openshift/modules/redis_env"
  namespace                   = var.name
  license                     = var.license
}
