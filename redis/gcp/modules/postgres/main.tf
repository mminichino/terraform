#

resource "helm_release" "postgres" {
  name             = "postgres"
  namespace        = "postgres"
  repository       = "https://mminichino.github.io/helm-charts"
  chart            = "postgres"
  version          = var.postgres_version
  create_namespace = true
  cleanup_on_fail  = true

  values = [
    yamlencode({
      postgres = {
        externalSecret = {
          enabled = true
          key = var.password_key
          store = {
            name = var.secret_store
          }
        }
        persistence = {
          storageClass = var.storage_class
        }
      }
      service = {
        ingress = {
          enabled = true
        }
      }
      dns = {
        domain = var.dns_domain
      }
      exporter = {
        enabled = true
      }
    })
  ]
}
