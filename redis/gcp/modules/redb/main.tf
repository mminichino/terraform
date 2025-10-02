#

locals {
  redis_db_hostname = "${var.name}.${var.domain_name}"
  ingress_enabled = contains(["nginx", "haproxy"], var.service_type)
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
  cleanup_on_fail  = true
  wait_for_jobs    = true

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
    },
    {
      name  = "ingress.type"
      value = var.service_type
    }
  ]

  set_list = [
    {
      name  = "modules"
      value = var.modules
    }
  ]
}

data "kubernetes_service_v1" "db_lb_service" {
  count = local.ingress_enabled ? 0 : 1
  metadata {
    name      = "${var.name}-load-balancer"
    namespace = var.namespace
  }
  depends_on = [helm_release.redis_database]
}

data "kubernetes_service_v1" "ingress_service" {
  count = local.ingress_enabled ? 1 : 0
  metadata {
    name      = var.ingress_service
    namespace = var.ingress_namespace
  }
  depends_on = [helm_release.redis_database]
}

locals {
  # noinspection HILUnresolvedReference
  service_ip = (local.ingress_enabled ?
    data.kubernetes_service_v1.ingress_service.0.status.0.load_balancer.0.ingress.0.ip :
    data.kubernetes_service_v1.db_lb_service.0.status.0.load_balancer.0.ingress.0.ip)
}

resource "google_dns_record_set" "db_record" {
  name = "${local.redis_db_hostname}."
  managed_zone = replace(var.domain_name, ".", "-")
  type = "A"
  ttl = 300
  rrdatas = [local.service_ip]
}
