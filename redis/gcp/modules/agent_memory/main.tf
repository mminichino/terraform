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
      name = "redis.service"
      value = var.redis_service
    },
    {
      name = "redis.port"
      value = var.redis_port
    },
    {
      name  = "externalSecret.store.name"
      value = var.external_secret_store
    },
    {
      name = "externalSecret.keys.password"
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

  set = flatten([
    {
      name = "dns.domain"
      value = var.domain_name
    },
    {
      name  = "externalSecret.store.name"
      value = var.external_secret_store
    },
    {
      name = "externalSecret.keys.openai"
      value = var.openai_secret_key
    },
    {
      name = "externalSecret.keys.tavily"
      value = var.tavily_secret_key
    },
    {
      name = "externalSecret.keys.password"
      value = var.password_secret_key
    },
    {
      name = "createDb"
      value = var.create_database
    },
    var.active_active ? [
      {
        name = "multiActive.enabled"
        value = var.active_active
      },
      {
        name = "multiActive.localCluster"
        value = var.local_cluster
      },
      {
        name = "multiActive.remoteCluster"
        value = var.remote_cluster
      },
      {
        name = "externalSecret.keys.database"
        value = var.database_key
      },
    ] : []
  ])
  depends_on = [helm_release.agent_memory_server]
}
