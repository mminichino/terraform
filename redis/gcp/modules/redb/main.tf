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

resource "kubernetes_manifest" "database" {
  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name      = var.name
      namespace = var.namespace
      annotations = {
        "kubernetes.io/ingress.class"                  = "nginx"
        "nginx.ingress.kubernetes.io/ssl-passthrough"  = "true"
      }
    }

    spec = {
      rules = [{
        host = "${var.name}.${var.domain_name}"
        http = {
          paths = [{
            path = "/"
            pathType = "ImplementationSpecific"
            backend = {
              service = {
                name = var.name
                port = {
                  number = var.port
                }
              }
            }
          }]
        }
      }]
    }
  }

  depends_on = [helm_release.redis_database]
}
