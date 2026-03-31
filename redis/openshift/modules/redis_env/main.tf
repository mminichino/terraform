#

locals {
  ingress_enabled = contains(["nginx", "haproxy"], var.service_type)
  cluster_name    = "${var.namespace}-cluster"
}

resource "helm_release" "redis_operator" {
  name             = "${var.namespace}-operator"
  namespace        = var.namespace
  repository       = "https://helm.redis.io"
  chart            = "redis-enterprise-operator"
  version          = var.operator_version
  create_namespace = true
  cleanup_on_fail  = true

  set = [
    {
      name  = "openshift.mode"
      value = true
    },
    {
      name  = "operator.image.repository"
      value = "registry.connect.redhat.com/redislabs/redis-enterprise-operator"
    }
  ]
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
      name  = "openshift"
      value = true
    },
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
  depends_on = [helm_release.redis_operator]
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
  name             = "${var.namespace}-redb"
  namespace        = var.namespace
  repository       = "https://mminichino.github.io/helm-charts"
  chart            = "redis-database"
  version          = var.database_chart_version
  cleanup_on_fail  = true
  wait_for_jobs    = true
  atomic           = true

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
      value = "lb"
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
  length           = 16
  special          = false
}

resource "helm_release" "rdidb_database" {
  name             = "${var.namespace}-rdidb"
  namespace        = var.namespace
  repository       = "https://mminichino.github.io/helm-charts"
  chart            = "redis-database"
  version          = var.database_chart_version
  cleanup_on_fail  = true
  wait_for_jobs    = true
  atomic           = true

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
      value = "lb"
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

data "kubernetes_secret_v1" "redis_cluster_secret" {
  metadata {
    name      = local.cluster_name
    namespace = var.namespace
  }
  depends_on = [helm_release.rdidb_database]
}

data "kubernetes_service_v1" "cluster_service" {
  metadata {
    name      = "${local.cluster_name}-ui"
    namespace = var.namespace
  }
  depends_on = [helm_release.redis_cluster]
}

data "kubernetes_service_v1" "redb_lb_service" {
  metadata {
    name      = "redb-load-balancer"
    namespace = var.namespace
  }
  depends_on = [helm_release.redb_database]
}

data "kubernetes_service_v1" "rdidb_lb_service" {
  metadata {
    name      = "rdidb-load-balancer"
    namespace = var.namespace
  }
  depends_on = [helm_release.rdidb_database]
}

locals {
  # noinspection HILUnresolvedReference
  cluster_ip = try(data.kubernetes_service_v1.cluster_service.status.0.load_balancer.0.ingress.0.ip, null)
  # noinspection HILUnresolvedReference
  redb_lb_ip = try(data.kubernetes_service_v1.redb_lb_service.status.0.load_balancer.0.ingress.0.ip, null)
  # noinspection HILUnresolvedReference
  rdidb_lb_ip = try(data.kubernetes_service_v1.rdidb_lb_service.status.0.load_balancer.0.ingress.0.ip, null)
}
