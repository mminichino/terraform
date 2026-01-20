#

data "google_client_openid_userinfo" "current" {}

data "google_project" "current" {}

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
  repository       = "https://kubernetes-sigs.github.io/external-dns"
  chart            = "external-dns"
  create_namespace = true
  cleanup_on_fail  = true

  values = [
    yamlencode({
      provider = {
        name = "google"
      }
      extraArgs = {
        "google-zone-visibility" = "public"
      }
      serviceAccount = {
        name = "external-dns"
        annotations = {
          "iam.gke.io/gcp-service-account" = local.sa_email
        }
      }
      txtOwnerId = "external-dns"
      domainFilters = [var.gke_domain_name]
    })
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

  values = [
    yamlencode({
      controller = {
        replicaCount = 2
        service = {
          type = "LoadBalancer"
          enablePorts = {
            http = true
            https = true
            quic = false
          }
          tcpPorts = [
            {
              name = "redis-12000"
              port: 12000
              targetPort: 12000
              protocol = "TCP"
            },
            {
              name = "redis-12001"
              port: 12001
              targetPort: 12001
              protocol = "TCP"
            },
            {
              name = "postgres"
              port: 5432
              targetPort: 5432
              protocol = "TCP"
            }
          ]
        }
      }
    })
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
  depends_on = [helm_release.haproxy_ingress, kubernetes_cluster_role_binding_v1.admin]
}

data "kubernetes_service_v1" "haproxy_ingress" {
  metadata {
    name      = "haproxy-ingress-kubernetes-ingress"
    namespace = "haproxy-ingress"
  }
  depends_on = [helm_release.prometheus]
}

# noinspection HILUnresolvedReference
locals {
  ingress_ip  = try(data.kubernetes_service_v1.haproxy_ingress.status.0.load_balancer.0.ingress.0.ip, null)
  ingress_zone_name = "ingress-${replace(var.gke_domain_name, ".", "-")}"
  ingress_dns_name  = "ingress.${var.gke_domain_name}"
}

resource "google_dns_managed_zone" "ingress" {
  name        = local.ingress_zone_name
  dns_name    = "${local.ingress_dns_name}."
  description = "Zone for ${local.ingress_dns_name}"

  provisioner "local-exec" {
    when    = destroy
    command = "gcloud dns record-sets list --project ${self.project} --zone ${self.name} --filter=\"type=A OR type=TXT\" --format='value(name,type.list(separator=\",\"))' | xargs -r -n2 sh -c 'gcloud dns record-sets delete $0 --project ${self.project} --zone ${self.name} --type $1'"
  }
}

resource "google_dns_record_set" "subdomain_ns_delegation" {
  name         = "${local.ingress_dns_name}."
  managed_zone = local.ingress_zone_name
  type         = "NS"
  ttl          = 300
  rrdatas      = google_dns_managed_zone.ingress.name_servers
}

resource "google_dns_record_set" "ingress_hostname" {
  name         = "haproxy.${local.ingress_dns_name}."
  managed_zone = local.ingress_zone_name
  type         = "A"
  ttl          = 300
  rrdatas      = [local.ingress_ip]
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

resource "helm_release" "gcsm_store" {
  name             = "gcsm-store"
  namespace        = "external-secrets"
  repository       = "https://mminichino.github.io/helm-charts"
  chart            = "gcsm-store"
  version          = "0.1.6"
  cleanup_on_fail  = true

  set = [
    {
      name  = "project"
      value = data.google_project.current.project_id
    }
  ]

  depends_on = [helm_release.external_secrets]
}
