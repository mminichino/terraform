#

resource "random_string" "grafana_password" {
  length           = 8
  special          = false
}

resource "kubernetes_service_account_v1" "grafana" {
  metadata {
    name      = "grafana"
    namespace = var.namespace
  }
}

resource "kubernetes_cluster_role_binding_v1" "grafana_cluster_monitoring_view" {
  metadata {
    name = "grafana-${var.namespace}-cluster-monitoring-view"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-monitoring-view"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.grafana.metadata[0].name
    namespace = var.namespace
  }
}

resource "helm_release" "grafana" {
  name            = "grafana"
  namespace       = var.namespace
  repository      = "https://grafana.github.io/helm-charts"
  chart           = "grafana"
  cleanup_on_fail = true

  set_sensitive = [
    {
      name  = "adminPassword"
      value = random_string.grafana_password.id
    }
  ]

  set = [
    {
      name  = "service.type"
      value = "ClusterIP"
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = kubernetes_service_account_v1.grafana.metadata[0].name
    }
  ]
}
