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

provider "kubernetes" {
  host                   = var.kubernetes_endpoint
  token                  = var.kubernetes_token
  cluster_ca_certificate = var.cluster_ca_certificate
}

data "kubernetes_service_v1" "nginx_ingress" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
}

resource "google_dns_record_set" "db_record" {
  name = "${var.name}.${var.domain_name}."
  managed_zone = replace(var.domain_name, ".", "-")
  type = "A"
  ttl = 300
  rrdatas = [data.kubernetes_service_v1.nginx_ingress.status.0.load_balancer.0.ingress.0.ip]
}
