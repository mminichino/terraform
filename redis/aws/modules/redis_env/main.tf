#

locals {
  ingress_enabled = contains(["nginx", "haproxy"], var.service_type)
  cluster_name    = "${var.namespace}-cluster"
  redis_ui_port   = local.ingress_enabled ? 443 : 8443
  redis_ui_name   = "ui-${local.cluster_name}"
  redis_ui_host   = "${local.redis_ui_name}.${var.domain_name}"
  redis_ui_url    = "https://${local.redis_ui_host}:${local.redis_ui_port}"
}

resource "helm_release" "redis_operator" {
  name             = "${var.namespace}-operator"
  namespace        = var.namespace
  repository       = "https://helm.redis.io"
  chart            = "redis-enterprise-operator"
  version          = var.operator_version
  create_namespace = true
  cleanup_on_fail  = true
  atomic           = true
}

resource "helm_release" "redis_cluster" {
  name              = "${var.namespace}-cluster"
  namespace         = var.namespace
  repository        = "https://mminichino.github.io/helm-charts"
  chart             = "redis-cluster"
  version           = var.cluster_chart_version
  dependency_update = true
  cleanup_on_fail   = true
  atomic            = true

  set = [
    {
      name  = "name"
      value = local.cluster_name
    },
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
      name  = "dns.domain"
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
  depends_on = [helm_release.redis_operator]
}

resource "kubernetes_manifest" "monitoring" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "redis-service-monitor"
      namespace = var.namespace
      labels = {
        release = "prometheus"
      }
    }
    spec = {
      endpoints = [
        {
          interval = "15s"
          port     = "prometheus"
          scheme   = "https"
          tlsConfig = {
            insecureSkipVerify = true
          }
        },
        {
          interval = "15s"
          port     = "prometheus"
          scheme   = "https"
          path     = "/v2"
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
  length  = 16
  special = false
}

resource "helm_release" "redb_database" {
  name            = "${var.namespace}-redb"
  namespace       = var.namespace
  repository      = "https://mminichino.github.io/helm-charts"
  chart           = "redis-database"
  version         = var.database_chart_version
  cleanup_on_fail = true
  wait_for_jobs   = true
  atomic          = true

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
      name  = "cluster"
      value = local.cluster_name
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
      name  = "ingress.type"
      value = "haproxy"
    },
    {
      name  = "dns.domain"
      value = var.domain_name
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
  depends_on = [kubernetes_manifest.monitoring]
}

resource "random_string" "rdidb_password" {
  length  = 16
  special = false
}

resource "helm_release" "rdidb_database" {
  name            = "${var.namespace}-rdidb"
  namespace       = var.namespace
  repository      = "https://mminichino.github.io/helm-charts"
  chart           = "redis-database"
  version         = var.database_chart_version
  cleanup_on_fail = true
  wait_for_jobs   = true
  atomic          = true

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
      name  = "cluster"
      value = local.cluster_name
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
      name  = "ingress.type"
      value = "haproxy"
    },
    {
      name  = "dns.domain"
      value = var.domain_name
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
  depends_on = [helm_release.redb_database]
}

resource "random_string" "redis_insight_password" {
  length  = 16
  special = false
}

resource "helm_release" "redis_insight" {
  name            = "${var.namespace}-insight"
  namespace       = var.namespace
  repository      = "https://mminichino.github.io/helm-charts"
  chart           = "redis-insight"
  cleanup_on_fail = true
  atomic          = true

  set = [
    {
      name  = "ingress.enabled"
      value = true
    },
    {
      name  = "ingress.password"
      value = random_string.redis_insight_password.id
    },
    {
      name  = "dns.domain"
      value = var.domain_name
    },
    {
      name  = "tls.enabled"
      value = true
    }
  ]
  depends_on = [helm_release.redis_cluster]
}
