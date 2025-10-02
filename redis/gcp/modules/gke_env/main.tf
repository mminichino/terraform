#

data "google_client_openid_userinfo" "current" {}

locals {
  sa_email = data.google_client_openid_userinfo.current.email
}

resource "random_string" "grafana_password" {
  length           = 8
  special          = false
}

resource "kubernetes_cluster_role_binding_v1" "admin" {
  metadata {
    name = "sa-admin-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind     = "User"
    name     = local.sa_email
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "helm_release" "external_dns" {
  name             = "external-dns"
  namespace        = "external-dns"
  repository       = "https://mminichino.github.io/helm-charts"
  chart            = "external-dns-gke"
  create_namespace = true
  cleanup_on_fail  = true

  set = [
    {
      name  = "googleServiceAccount"
      value = local.sa_email
    }
  ]

  set_list = [
    {
      name  = "domainFilters"
      value = [var.gke_domain_name]
    }
  ]
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.18.2"
  create_namespace = true
  cleanup_on_fail  = true

  set = [
    {
      name  = "crds.enabled"
      value = true
    }
  ]

  depends_on = [helm_release.external_dns]
}

resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  create_namespace = true
  cleanup_on_fail  = true

  set = [
    {
      name  = "tcp.12000"
      value = "redis/redb1:12000"
    },
    {
      name  = "tcp.12001"
      value = "redis/redb2:12001"
    },
    {
      name  = "tcp.12002"
      value = "redis/redb3:12002"
    },
    {
      name  = "tcp.12003"
      value = "redis/redb4:12003"
    }
  ]

  depends_on = [helm_release.cert_manager]
}

locals {
  grafana_hostname = "grafana.${var.gke_domain_name}"
}

resource "helm_release" "prometheus" {
  name             = "prometheus"
  namespace        = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  create_namespace = true
  cleanup_on_fail  = true

  set = [
    {
      name  = "grafana.ingress.enabled"
      value = true
    },
    {
      name  = "grafana.ingress.annotations.kubernetes\\.io/ingress\\.class"
      value = "nginx"
    }
  ]

  set_list = [
    {
      name  = "grafana.ingress.hosts"
      value = [local.grafana_hostname]
    }
  ]

  set_sensitive = [
    {
      name  = "grafana.adminPassword"
      value = random_string.grafana_password.id
    }
  ]
  depends_on = [helm_release.nginx_ingress, kubernetes_cluster_role_binding_v1.admin]
}

data "kubernetes_service_v1" "nginx_ingress" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
  depends_on = [helm_release.prometheus]
}

# noinspection HILUnresolvedReference
locals {
  nginx_ingress_ip = data.kubernetes_service_v1.nginx_ingress.status.0.load_balancer.0.ingress.0.ip
}
