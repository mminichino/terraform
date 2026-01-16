#

resource "random_string" "grafana_password" {
  length           = 8
  special          = false
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
      name  = "externalDnsOciConfig.auth.region"
      value = var.region
    },
    {
      name  = "externalDnsOciConfig.compartment"
      value = var.compartment_ocid
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

resource "helm_release" "haproxy_ingress" {
  name             = "haproxy-ingress"
  namespace        = "haproxy-ingress"
  repository       = "https://haproxytech.github.io/helm-charts"
  chart            = "kubernetes-ingress"
  version          = "1.46.1"
  create_namespace = true
  cleanup_on_fail  = true

  set = [
    {
      name  = "controller.replicaCount"
      value = 2
    },
    {
      name  = "controller.service.type"
      value = "LoadBalancer"
    },
    {
      name  = "controller.service.enablePorts.http"
      value = true
    },
    {
      name  = "controller.service.enablePorts.https"
      value = true
    },
    {
      name  = "controller.service.enablePorts.quic"
      value = false
    }
  ]

  depends_on = [helm_release.cert_manager]
}

locals {
  grafana_hostname = "grafana.${var.domain_name}"
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
      value = "haproxy"
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
  depends_on = [helm_release.haproxy_ingress]
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  namespace        = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "1.2.1"
  create_namespace = true
  cleanup_on_fail  = true
}
