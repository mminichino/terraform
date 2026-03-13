#

resource "helm_release" "agent_memory_server" {
  name             = "${var.namespace}-ams"
  namespace        = var.namespace
  repository       = "https://mminichino.github.io/redis-agent-memory-demo"
  chart            = "agent-memory-server"
  version          = var.chart_version
  cleanup_on_fail  = true
  wait_for_jobs    = true
  atomic           = true

  set = [
    {
      name  = "redis.url"
      value = var.redis_url
    },
    {
      name = "openai.key"
      value = var.openai_key
    }
  ]
}
