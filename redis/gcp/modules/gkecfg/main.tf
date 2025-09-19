#

resource "random_string" "grafana_password" {
  length           = 8
  special          = false
}

provider "helm" {
  kubernetes = {
    host                   = var.kubernetes_endpoint
    token                  = var.kubernetes_token
    cluster_ca_certificate = var.cluster_ca_certificate
  }
}

provider "kubernetes" {
  host                   = var.kubernetes_endpoint
  token                  = var.kubernetes_token
  cluster_ca_certificate = var.cluster_ca_certificate
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
    name     = var.service_account_email
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "helm_release" "external_dns" {
  name             = "external-dns"
  namespace        = "external-dns"
  repository       = "https://mminichino.github.io/helm-charts"
  chart            = "external-dns-gke"
  create_namespace = true

  set = [
    {
      name  = "googleServiceAccount"
      value = var.service_account_email
    }
  ]

  set_list = [
    {
      name  = "domainFilters"
      value = [var.domain_name]
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

  depends_on = [helm_release.cert_manager]
}

resource "helm_release" "prometheus" {
  name             = "prometheus"
  namespace        = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  create_namespace = true

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
      value = ["grafana.${var.domain_name}"]
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
