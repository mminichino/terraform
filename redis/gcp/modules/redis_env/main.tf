#

locals {
  ingress_enabled = contains(["nginx", "haproxy"], var.service_type)
  # redis_ui_url_port = local.ingress_enabled ? 443 : 8443
}

resource "helm_release" "redis_cluster" {
  name             = var.namespace
  namespace        = var.namespace
  repository       = "https://mminichino.github.io/helm-charts"
  chart            = "redis-cluster"
  version          = var.chart_version
  create_namespace = true
  cleanup_on_fail  = true

  set = [
    {
      name  = "license"
      value = var.license
    },
    {
      name  = "namespace"
      value = var.namespace
    },
    {
      name  = "ingress.enabled"
      value = local.ingress_enabled
    },
    {
      name  = "ingress.type"
      value = var.service_type
    },
    {
      name = "dns.domain"
      value = var.domain_name
    },
    {
      name  = "tls.secret"
      value = var.tls_secret
    },
    {
      name  = "node.count"
      value = var.mode_count
    },
    {
      name  = "node.cpu"
      value = var.cpu
    },
    {
      name  = "node.memory"
      value = var.memory
    },
    {
      name  = "node.disk"
      value = var.volume_size
    },
    {
      name  = "storage.class"
      value = var.storage_class
    },
    {
      name  = "externalSecret.enabled"
      value = var.external_secret_enabled
    },
    {
      name  = "externalSecret.store.name"
      value = var.external_secret_store
    },
    {
      name  = "externalSecret.key"
      value = var.external_secret_cluster_key
    }
  ]
}

resource "kubernetes_manifest" "monitoring" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind = "ServiceMonitor"
    metadata = {
      name = "redis-service-monitor"
      namespace = var.namespace
      labels = {
        release = "prometheus"
      }
    }
    spec = {
      endpoints = [
        {
          interval = "15s"
          port = "prometheus"
          scheme = "https"
          tlsConfig = {
            insecureSkipVerify = true
          }
        },
        {
          interval = "15s"
          port = "prometheus"
          scheme = "https"
          path = "/v2"
          tlsConfig = {
            insecureSkipVerify = true
          }
        }
      ]
      namespaceSelector = {
        matchNames = [var.namespace]
      }
      selector = {
        matchLabels = {
          "redis.io/service" = "prom-metrics"
        }
      }
    }
  }

  depends_on = [helm_release.redis_cluster]
}

resource "random_string" "redb_password" {
  length           = 16
  special          = false
}

resource "helm_release" "redb_database" {
  name             = "redb"
  namespace        = var.namespace
  repository       = "https://mminichino.github.io/helm-charts"
  chart            = "redis-database"
  cleanup_on_fail  = true
  wait_for_jobs    = true

  set = [
    {
      name  = "name"
      value = "redb"
    },
    {
      name  = "password"
      value = random_string.redb_password.id
    },
    {
      name = "cluster"
      value = "${var.namespace}-cluster"
    },
    {
      name  = "memory"
      value = "1GB"
    },
    {
      name  = "replication"
      value = true
    },
    {
      name  = "shards"
      value = 1
    },
    {
      name  = "placement"
      value = "sparse"
    },
    {
      name  = "port"
      value = 12000
    },
    {
      name  = "eviction"
      value = "noeviction"
    },
    {
      name  = "externalSecret.enabled"
      value = var.external_secret_enabled
    },
    {
      name  = "externalSecret.store.name"
      value = var.external_secret_store
    },
    {
      name  = "externalSecret.key"
      value = var.external_secret_redb_key
    }
  ]

  set_list = [
    {
      name  = "modules"
      value = []
    }
  ]
  depends_on = [helm_release.redis_cluster]
}

resource "random_string" "rdidb_password" {
  length           = 16
  special          = false
}

resource "helm_release" "rdidb_database" {
  name             = "rdidb"
  namespace        = var.namespace
  repository       = "https://mminichino.github.io/helm-charts"
  chart            = "redis-database"
  cleanup_on_fail  = true
  wait_for_jobs    = true

  set = [
    {
      name  = "name"
      value = "rdidb"
    },
    {
      name  = "password"
      value = random_string.rdidb_password.id
    },
    {
      name = "cluster"
      value = "${var.namespace}-cluster"
    },
    {
      name  = "memory"
      value = "256MB"
    },
    {
      name  = "replication"
      value = true
    },
    {
      name  = "shards"
      value = 1
    },
    {
      name  = "placement"
      value = "sparse"
    },
    {
      name  = "port"
      value = 12001
    },
    {
      name  = "eviction"
      value = "noeviction"
    },
    {
      name  = "externalSecret.enabled"
      value = var.external_secret_enabled
    },
    {
      name  = "externalSecret.store.name"
      value = var.external_secret_store
    },
    {
      name  = "externalSecret.key"
      value = var.external_secret_rdidb_key
    }
  ]

  set_list = [
    {
      name  = "modules"
      value = []
    }
  ]
  depends_on = [helm_release.redis_cluster]
}

data "kubernetes_secret_v1" "redis_cluster_secret" {
  metadata {
    name      = "${var.namespace}-cluster"
    namespace = var.namespace
  }
  depends_on = [helm_release.rdidb_database]
}
