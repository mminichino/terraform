#

resource "helm_release" "redis_operator" {
  name             = "redis"
  namespace        = var.namespace
  repository       = "https://helm.redis.io"
  chart            = "redis-enterprise-operator"
  version          = var.operator_version
  create_namespace = true
}
