#

provider "helm" {
  kubernetes = {
    host                   = var.kubernetes_endpoint
    token                  = var.kubernetes_token
    cluster_ca_certificate = var.cluster_ca_certificate
  }
}

resource "helm_release" "redis_operator" {
  name             = "redis"
  namespace        = var.namespace
  repository       = "https://helm.redis.io"
  chart            = "redis-enterprise-operator"
  version          = "7.22.0-17"
  create_namespace = true
}
