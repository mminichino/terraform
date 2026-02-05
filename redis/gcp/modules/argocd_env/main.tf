#

resource "helm_release" "argocd_config" {
  name             = "argocd-config"
  namespace        = var.namespace
  repository       = "https://mminichino.github.io/helm-charts"
  chart            = "argocd-config"
  version          = var.argocd_config_version
  cleanup_on_fail  = true

  set = [
    {
      name  = "repository"
      value = var.repository
    },
    {
      name  = "externalSecret.store.name"
      value = var.external_secret_store
    },
    {
      name  = "externalSecret.key"
      value = var.external_secret_key
    }
  ]
}
