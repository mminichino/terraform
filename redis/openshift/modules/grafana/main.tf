#

resource "random_string" "grafana_password" {
  length           = 8
  special          = false
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
}

resource "kubernetes_manifest" "grafana_token" {
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Secret"
    "metadata" = {
      "name"      = "grafana-token"
      "namespace" = var.namespace
      "annotations" = {
        "kubernetes.io/service-account.name" = "grafana"
      }
    }
    "type" = "kubernetes.io/service-account-token"
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
    },
    {
      name  = "extraVolumes[0].name"
      value = "serviceaccount-token"
    },
    {
      name  = "extraVolumes[0].secret.secretName"
      value = "grafana-token"
    },
    {
      name  = "extraVolumeMounts[0].name"
      value = "serviceaccount-token"
    },
    {
      name  = "extraVolumeMounts[0].mountPath"
      value = "/var/run/secrets/kubernetes.io/serviceaccount"
    },
    {
      name  = "datasources.datasources\\.yaml.apiVersion"
      value = "1"
    },
    {
      name  = "datasources.datasources\\.yaml.datasources[0].name"
      value = "Prometheus"
    },
    {
      name  = "datasources.datasources\\.yaml.datasources[0].type"
      value = "prometheus"
    },
    {
      name  = "datasources.datasources\\.yaml.datasources[0].url"
      value = "https://thanos-querier.openshift-monitoring.svc:9091"
    },
    {
      name  = "datasources.datasources\\.yaml.datasources[0].access"
      value = "proxy"
    },
    {
      name  = "datasources.datasources\\.yaml.datasources[0].isDefault"
      value = "true"
    },
    {
      name  = "datasources.datasources\\.yaml.datasources[0].jsonData.httpHeaderName1"
      value = "Authorization"
    },
    {
      name  = "datasources.datasources\\.yaml.datasources[0].jsonData.tlsSkipVerify"
      value = "true"
    },
    {
      name  = "datasources.datasources\\.yaml.datasources[0].secureJsonData.httpHeaderValue1"
      value = "Bearer $TOKEN"
    },
    {
      name  = "sidecar.datasources.enabled"
      value = "true"
    },
    {
      name  = "sidecar.datasources.label"
      value = "grafana_datasource"
    },
    {
      name  = "sidecar.dashboards.enabled"
      value = "true"
    },
    {
      name  = "sidecar.dashboards.label"
      value = "grafana_dashboard"
    }
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
}
