#

resource "random_string" "grafana_password" {
  length           = 8
  special          = false
}

resource "kubernetes_namespace_v1" "grafana" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_manifest" "cluster-monitoring-configmap" {
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "ConfigMap"
    "metadata" = {
      "name"      = "cluster-monitoring-config"
      "namespace" = "openshift-monitoring"
    }
    data = {
      "config.yaml" = <<-EOT
        enableUserWorkload: true
      EOT
    }
  }
}

resource "kubernetes_service_account_v1" "grafana" {
  metadata {
    name      = "grafana"
    namespace = var.namespace
  }
  depends_on = [kubernetes_namespace_v1.grafana]
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
  depends_on = [kubernetes_namespace_v1.grafana]
}

resource "kubernetes_role_binding_v1" "grafana_scc_anyuid" {
  metadata {
    name      = "grafana-scc-anyuid"
    namespace = var.namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:openshift:scc:anyuid"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.grafana.metadata[0].name
    namespace = var.namespace
  }
  depends_on = [kubernetes_namespace_v1.grafana]
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

  values = [
    <<-YAML
    podSecurityContext: null
    securityContext: null
    containerSecurityContext: null
    podAnnotations: {}
    serviceAccount:
      create: false
      name: ${kubernetes_service_account_v1.grafana.metadata[0].name}
      automountServiceAccountToken: true
    service:
      type: ClusterIP
    datasources:
      datasources.yaml:
        apiVersion: 1
        datasources:
          - name: Prometheus
            type: prometheus
            url: https://thanos-querier.openshift-monitoring.svc:9091
            access: proxy
            isDefault: true
            jsonData:
              httpHeaderName1: Authorization
              tlsSkipVerify: true
            secureJsonData:
              httpHeaderValue1: "Bearer $__file{/var/run/secrets/kubernetes.io/serviceaccount/token}"
    sidecar:
      datasources:
        enabled: true
        label: grafana_datasource
      dashboards:
        enabled: true
        label: grafana_dashboard
    YAML
  ]

  depends_on = [
    kubernetes_namespace_v1.grafana,
    kubernetes_role_binding_v1.grafana_scc_anyuid
  ]
}

resource "kubernetes_manifest" "grafana_route" {
  manifest = {
    "apiVersion" = "route.openshift.io/v1"
    "kind"       = "Route"
    "metadata" = {
      "name"      = "grafana"
      "namespace" = var.namespace
    }
    "spec" = {
      "to" = {
        "kind" = "Service"
        "name" = "grafana"
      }
      "tls" = {
        "termination" = "edge"
      }
    }
  }
  depends_on = [kubernetes_namespace_v1.grafana]
}
