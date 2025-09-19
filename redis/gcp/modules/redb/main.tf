#

provider "helm" {
  kubernetes = {
    host                   = var.kubernetes_endpoint
    token                  = var.kubernetes_token
    cluster_ca_certificate = var.cluster_ca_certificate
  }
}

resource "random_string" "password" {
  length           = 8
  special          = false
}

resource "helm_release" "redis_database" {
  name             = var.name
  namespace        = var.namespace
  repository       = "https://mminichino.github.io/helm-charts"
  chart            = "redis-database"

  set = [
    {
      name  = "name"
      value = var.name
    },
    {
      name  = "password"
      value = random_string.password.id
    },
    {
      name = "cluster"
      value = var.cluster
    },
    {
      name  = "memory"
      value = var.memory
    },
    {
      name  = "replication"
      value = var.replication
    },
    {
      name  = "shards"
      value = var.shards
    },
    {
      name  = "placement"
      value = var.placement
    },
    {
      name  = "port"
      value = var.port
    },
    {
      name  = "eviction"
      value = var.eviction
    }
  ]

  set_list = [
    {
      name  = "modules"
      value = var.modules
    }
  ]
}

provider "kubernetes" {
  host                   = var.kubernetes_endpoint
  token                  = var.kubernetes_token
  cluster_ca_certificate = var.cluster_ca_certificate
}

resource "kubernetes_manifest" "redis_port" {
  manifest = {
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "tcp-services"
      namespace = "ingress-nginx"
    }
    data = {
      tostring(var.port) = "${var.namespace}/${var.name}:${var.port}"
    }
  }

  field_manager {
    name            = "terraform"
    force_conflicts = false
  }
}
