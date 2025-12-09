#

locals {
  argocd_hostname = "argocd.${var.gke_domain_name}"
}

resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_manifest" "self_signed_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "self-signed-issuer"
      namespace = "argocd"
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
  depends_on = [kubernetes_namespace_v1.argocd]
}

resource "kubernetes_manifest" "argocd_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "argocd-server-tls"
      namespace = "argocd"
    }
    spec = {
      secretName = "argocd-server-tls"
      issuerRef = {
        name = "self-signed-issuer"
        kind = "Issuer"
      }
      dnsNames = [local.argocd_hostname]
    }
  }
  wait {
    fields = {
      "status.conditions[0].type" = "Ready"
    }
  }
  depends_on = [kubernetes_manifest.self_signed_issuer]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  cleanup_on_fail  = true

  set = [
    {
      name  = "server.tls"
      value = true
    }
  ]
  depends_on = [kubernetes_manifest.argocd_certificate]
}

resource "kubernetes_ingress_v1" "argocd_ui" {
  wait_for_load_balancer = true
  metadata {
    name      = "argocd-server"
    namespace = "argocd"
    annotations = {
      "ingress.kubernetes.io/ssl-passthrough"  = "true"
    }
  }
  spec {
    ingress_class_name = "haproxy"
    rule {
      host = local.argocd_hostname
      http {
        path {
          path = "/"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "argocd-server"
              port {
                number = 443
              }
            }
          }
        }
      }
    }
  }
  depends_on = [helm_release.argocd]
}

data "kubernetes_secret_v1" "argocd_admin_password" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = kubernetes_namespace_v1.argocd.metadata[0].name
  }
  depends_on = [helm_release.argocd]
}

resource "kubernetes_config_map_v1" "cluster_settings" {
  metadata {
    name      = "cluster-settings"
    namespace = "argocd"
  }

  data = {
    "config" = <<-EOT
domain: "${var.gke_domain_name}"
EOT
  }
  depends_on = [kubernetes_namespace_v1.argocd]
}
