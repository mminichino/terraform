#

resource "kubernetes_service_account_v1" "kubeconfig_sa" {
  metadata {
    name      = var.service_account_name
    namespace = var.namespace
  }
}

resource "kubernetes_cluster_role_binding_v1" "sa_binding" {
  metadata {
    name = var.cluster_role_binding_name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.kubeconfig_sa.metadata[0].name
    namespace = kubernetes_service_account_v1.kubeconfig_sa.metadata[0].namespace
  }
}

resource "kubernetes_secret_v1" "sa_token" {
  metadata {
    name      = var.service_account_token_secret
    namespace = var.namespace
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.kubeconfig_sa.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"

  depends_on = [
    kubernetes_service_account_v1.kubeconfig_sa
  ]
}

data "kubernetes_secret_v1" "sa_token" {
  metadata {
    name      = kubernetes_secret_v1.sa_token.metadata[0].name
    namespace = kubernetes_secret_v1.sa_token.metadata[0].namespace
  }

  depends_on = [
    kubernetes_secret_v1.sa_token
  ]
}

locals {
  bearer_token = data.kubernetes_secret_v1.sa_token.data["token"]

  kubeconfig = yamlencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      name = var.cluster_name
      cluster = {
        server                       = var.api_server
        "certificate-authority-data" = var.ca_data
      }
    }]
    users = [{
      name = var.service_account_name
      user = {
        token = local.bearer_token
      }
    }]
    contexts = [{
      name = var.cluster_name
      context = {
        cluster = var.cluster_name
        user    = var.service_account_name
      }
    }]
    "current-context" = var.cluster_name
  })
}

resource "local_sensitive_file" "kubeconfig" {
  filename = "~/.oci/${var.kubeconfig_filename}"
  content  = local.kubeconfig
}
