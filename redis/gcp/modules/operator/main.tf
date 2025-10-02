#

resource "random_string" "password" {
  length           = 8
  special          = false
}

resource "helm_release" "redis_operator" {
  name             = "redis"
  namespace        = var.namespace
  repository       = "https://helm.redis.io"
  chart            = "redis-enterprise-operator"
  version          = var.operator_version
  create_namespace = true
  cleanup_on_fail  = true
}

locals {
  dns_name = "*.${var.gke_domain_name}"
}

resource "kubernetes_manifest" "self_signed_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "self-signed-issuer"
      namespace = var.namespace
    }
    spec = {
      selfSigned = {}
    }
  }
  wait {
    fields = {
      "status.conditions[0].type" = "Ready"
    }
  }
  depends_on = [helm_release.redis_operator]
}

resource "kubernetes_secret_v1" "keystore_secret" {
  metadata {
    name      = "${var.tls_secret}-keystore"
    namespace = var.namespace
  }
  type = "Opaque"
  data = {
    password = random_string.password.id
  }
  depends_on = [kubernetes_manifest.self_signed_issuer]
}

resource "kubernetes_manifest" "argocd_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = var.tls_secret
      namespace = var.namespace
    }
    spec = {
      secretName = var.tls_secret
      issuerRef = {
        name = "self-signed-issuer"
        kind = "Issuer"
      }
      subject = {
        organizations = ["RedisLabs"]
        countries = ["US"]
      }
      dnsNames = [local.dns_name]
      keystores = {
        pkcs12 = {
          create = true
          passwordSecretRef = {
            name = "${var.tls_secret}-keystore"
            key = "password"
          }
        }
      }
    }
  }
  wait {
    fields = {
      "status.conditions[0].type" = "Ready"
    }
  }
  depends_on = [kubernetes_secret_v1.keystore_secret]
}
