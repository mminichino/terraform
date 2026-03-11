#

resource "helm_release" "reaadb_database" {
  name             = "${var.namespace}-reaadb"
  namespace        = var.namespace
  repository       = "https://mminichino.github.io/helm-charts"
  chart            = "active-active"
  version          = var.reaadb_chart_version
  cleanup_on_fail  = true
  wait_for_jobs    = true

  set = [
    {
      name  = "name"
      value = var.name
    },
    {
      name = "username"
      value = var.username
    },
    {
      name = "localName"
      value = var.localName
    },
    {
      name = "remoteName"
      value = var.remoteName
    },
    {
      name = "localClusterName"
      value = var.localClusterName
    },
    {
      name = "remoteClusterName"
      value = var.remoteClusterName
    },
    {
      name = "localNamespace"
      value = var.localNamespace
    },
    {
      name = "remoteNamespace"
      value = var.remoteNamespace
    },
    {
      name  = "memory"
      value = var.memory
    },
    {
      name  = "shards"
      value = var.shards
    },
    {
      name  = "port"
      value = var.port
    },
    {
      name  = "dns.localDomain"
      value = var.localDomain
    },
    {
      name  = "dns.remoteDomain"
      value = var.remoteDomain
    },
    {
      name  = "externalSecret.store.name"
      value = var.external_secret_store
    },
    {
      name  = "externalSecret.clusterKey"
      value = var.cluster_key
    },
    {
      name  = "externalSecret.databaseKey"
      value = var.reaadb_key
    }
  ]
}
