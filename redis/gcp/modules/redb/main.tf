#

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

resource "kubernetes_job_v1" "lb_ip_wait" {
  count = var.ingress_enabled ? 0 : 1
  metadata {
    name      = "lb-ip-wait-job"
    namespace = var.namespace
    labels = {
      app = "redis"
    }
  }

  wait_for_completion = true
  timeouts {
    create = "6m"
    update = "6m"
  }

  spec {
    backoff_limit = 0

    template {
      metadata {
        labels = {
          app = "redis"
        }
      }

      spec {
        service_account_name = "redis-enterprise-operator"
        restart_policy       = "Never"

        container {
          name  = "kubectl-wait"
          image = "bitnami/kubectl:latest"

          command = [
            "kubectl", "wait",
            "--for=jsonpath={.status.loadBalancer.ingress[0].ip}",
            "service/${var.name}-load-balancer",
            "--timeout=5m",
            "-n",
            var.namespace
          ]
        }
      }
    }
  }
  depends_on = [helm_release.redis_database]
}

data "kubernetes_service_v1" "db_lb_service" {
  count = var.ingress_enabled ? 0 : 1
  metadata {
    name      = "${var.name}-load-balancer"
    namespace = var.namespace
  }
  depends_on = [kubernetes_job_v1.lb_ip_wait]
}

locals {
  redis_db_hostname = "${var.name}.${var.domain_name}"
  # noinspection HILUnresolvedReference
  service_ip = var.ingress_enabled ? var.nginx_ingress_ip : data.kubernetes_service_v1.db_lb_service.0.status.0.load_balancer.0.ingress.0.ip
}

resource "google_dns_record_set" "db_record" {
  name = "${local.redis_db_hostname}."
  managed_zone = replace(var.domain_name, ".", "-")
  type = "A"
  ttl = 300
  rrdatas = [local.service_ip]
}
