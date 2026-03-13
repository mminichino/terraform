#

resource "helm_release" "agent_memory_server" {
  name             = "${var.namespace}-ams"
  namespace        = var.namespace
  repository       = "https://mminichino.github.io/redis-agent-memory-demo"
  chart            = "agent-memory-server"
  version          = var.server_chart_version
  cleanup_on_fail  = true
  wait_for_jobs    = true
  atomic           = true

  set = [
    {
      name  = "externalSecret.enabled"
      value = var.external_secret_enabled
    },
    {
      name  = "externalSecret.store.name"
      value = var.external_secret_store
    },
    {
      name = "externalSecret.keys.redis"
      value = var.redis_secret_key
    },
    {
      name = "externalSecret.keys.openai"
      value = var.openai_secret_key
    }
  ]
}

resource "helm_release" "agent_memory_demo" {
  name             = "${var.namespace}-ams-demo"
  namespace        = var.namespace
  repository       = "https://mminichino.github.io/redis-agent-memory-demo"
  chart            = "agent-memory-demo"
  version          = var.demo_chart_version
  cleanup_on_fail  = true
  wait_for_jobs    = true
  atomic           = true

  set = [
    {
      name = "dns.domain"
      value = var.domain_name
    },
    {
      name = "server.url"
      value = var.server_url
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
      name = "externalSecret.keys.openai"
      value = var.redis_secret_key
    },
    {
      name = "externalSecret.keys.tavily"
      value = var.openai_secret_key
    },
    {
      name = "externalSecret.keys.password"
      value = var.openai_secret_key
    }
  ]
  depends_on = [helm_release.agent_memory_server]
}
