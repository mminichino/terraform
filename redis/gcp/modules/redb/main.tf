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

locals {
  redis_db_hostname = "${var.name}.${var.domain_name}"
}

resource "google_dns_record_set" "db_record" {
  name = "${local.redis_db_hostname}."
  managed_zone = replace(var.domain_name, ".", "-")
  type = "A"
  ttl = 300
  rrdatas = [var.nginx_ingress_ip]
}
