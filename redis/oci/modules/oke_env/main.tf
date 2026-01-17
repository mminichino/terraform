#

resource "random_string" "grafana_password" {
  length           = 8
  special          = false
}

data "oci_identity_compartment" "compartment" {
  id = var.compartment_ocid
}

resource "oci_identity_policy" "external_dns_policy" {
  compartment_id = var.compartment_ocid
  description    = "OKE External DNS Policy"
  name           = "oke-external-dns"
  statements     = ["Allow any-user to manage dns in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type='workload',request.principal.cluster_id='${var.cluster_ocid}',request.principal.service_account='external-dns'}"]
}

resource "helm_release" "external_dns" {
  name             = "external-dns"
  namespace        = "external-dns"
  repository       = "https://mminichino.github.io/helm-charts"
  chart            = "external-dns-oci"
  create_namespace = true
  cleanup_on_fail  = true
  # atomic           = true

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
    },
    {
      name  = "controller.image.repository"
      value = "docker.io/haproxytech/kubernetes-ingress"
    },
    {
      name  = "controller.image.tag"
      value = "3.1.15"
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

resource "oci_identity_policy" "external_secrets_policy" {
  compartment_id = var.compartment_ocid
  description    = "OKE External Secrets Policy"
  name           = "oke-external-secrets"
  statements     = [
    "Allow any-user to inspect vaults in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type='workload',request.principal.cluster_id='${var.cluster_ocid}',request.principal.service_account='external-secrets'}",
    "Allow any-user to read secret-bundles in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type='workload',request.principal.cluster_id='${var.cluster_ocid}',request.principal.service_account='external-secrets'}",
    "Allow any-user to read secrets in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type='workload',request.principal.cluster_id='${var.cluster_ocid}',request.principal.service_account='external-secrets'}",
    "Allow any-user to read vaults in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type='workload',request.principal.cluster_id='${var.cluster_ocid}',request.principal.service_account='external-secrets'}",
    "Allow any-user to use keys in compartment ${data.oci_identity_compartment.compartment.name} where all {request.principal.type='workload',request.principal.cluster_id='${var.cluster_ocid}',request.principal.service_account='external-secrets'}"
  ]
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

resource "helm_release" "oracle_vault_store" {
  name             = "oracle-vault-store"
  namespace        = "external-secrets"
  repository       = "https://mminichino.github.io/helm-charts"
  chart            = "oracle-vault-store"
  version          = "0.1.2"
  cleanup_on_fail  = true

  set = [
    {
      name  = "vault"
      value = var.vault_ocid
    },
    {
      name  = "compartment"
      value = var.compartment_ocid
    },
    {
      name  = "region"
      value = var.region
    }
  ]

  depends_on = [helm_release.external_secrets]
}
