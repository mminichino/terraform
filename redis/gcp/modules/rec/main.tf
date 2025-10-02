#

locals {
  ingress_enabled = contains(["nginx", "haproxy"], var.service_type)
  redis_ui_dns_name = "redis-ui.${var.domain_name}"
  redis_ui_url_port = local.ingress_enabled ? 443 : 8443
  redis_ui_url = "https://${local.redis_ui_dns_name}:${local.redis_ui_url_port}"
}

resource "helm_release" "redis_cluster" {
  name             = var.name
  namespace        = var.namespace
  repository       = "https://mminichino.github.io/helm-charts"
  chart            = "redis-cluster"
  cleanup_on_fail  = true

  set = [
    {
      name  = "name"
      value = var.name
    },
    {
      name  = "ingress.enabled"
      value = local.ingress_enabled
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
    }
  ]
}

data "kubernetes_service_v1" "ui_lb_service" {
  count = local.ingress_enabled ? 0 : 1
  metadata {
    name      = "${var.name}-ui"
    namespace = var.namespace
  }
  depends_on = [helm_release.redis_cluster]
}

resource "google_dns_record_set" "ui_record" {
  count = local.ingress_enabled ? 0 : 1
  name = "${local.redis_ui_dns_name}."
  managed_zone = replace(var.domain_name, ".", "-")
  type = "A"
  ttl = 300
  # noinspection HILUnresolvedReference
  rrdatas = [data.kubernetes_service_v1.ui_lb_service.0.status.0.load_balancer.0.ingress.0.ip]
}

resource "kubernetes_manifest" "monitoring" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind = "ServiceMonitor"
    metadata = {
      name = "redis-enterprise"
      namespace = var.namespace
      labels = {
        release = "prometheus"
      }
    }
    spec = {
      endpoints = [{
        interval = "15s"
        port = "prometheus"
        scheme = "https"
        tlsConfig = {
          insecureSkipVerify = true
        }
      }]
      namespaceSelector = {
        matchNames = ["redis"]
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

data "kubernetes_secret_v1" "redis_cluster_secret" {
  metadata {
    name = var.name
    namespace = var.namespace
  }
  depends_on = [kubernetes_manifest.monitoring]
}
