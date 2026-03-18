#

resource "helm_release" "reaadb_database" {
  name             = "${var.namespace}-reaadb"
  namespace        = var.namespace
  repository       = "https://mminichino.github.io/helm-charts"
  chart            = "active-active"
  cleanup_on_fail  = true
  wait_for_jobs    = true
  atomic           = true

  values = [
    yamlencode({
      databases         = var.databases
      username          = var.username
      localName         = var.localName
      remoteName        = var.remoteName
      localClusterName  = var.localClusterName
      remoteClusterName = var.remoteClusterName
      localNamespace    = var.localNamespace
      remoteNamespace   = var.remoteNamespace
      ingress           = {
        enabled = var.ingressEnabled
      }
      dns = {
        localDomain  = var.localDomain
        remoteDomain = var.remoteDomain
      }
      externalSecret = {
        store = {
          name = var.external_secret_store
        }
        clusterKey  = var.cluster_key
        databaseKey = var.reaadb_key
      }
    })
  ]
}
