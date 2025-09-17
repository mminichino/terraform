#

provider "google" {
  credentials = file(var.credential_file)
  project     = var.gcp_project_id
  region      = var.gcp_region
}

data "google_container_engine_versions" "gke_version" {
  location = var.gcp_region
}

data "google_client_openid_userinfo" "current" {}

locals {
  cluster_name = "${var.name}-gke"
}

resource "google_container_cluster" "kubernetes" {
  name                     = local.cluster_name
  location                 = var.gcp_region
  network                  = var.network_name
  subnetwork               = var.subnet_name
  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false
  datapath_provider        = "ADVANCED_DATAPATH"

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  addons_config {
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
    gcp_filestore_csi_driver_config {
      enabled = true
    }
    http_load_balancing {
      disabled = false
    }
  }

  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = "0.0.0.0/0"
    }
  }

  resource_labels = merge(var.labels, {
    name       = local.cluster_name
    managed_by = "terraform"
  })
}

locals {
  node_pool_name = "${var.name}-node-pool"
}

resource "google_container_node_pool" "worker_nodes" {
  name       = local.node_pool_name
  location   = var.gcp_region
  cluster    = google_container_cluster.kubernetes.name

  version = data.google_container_engine_versions.gke_version.release_channel_default_version["REGULAR"]
  node_count = var.node_count

  autoscaling {
    min_node_count = var.node_count
    max_node_count = var.max_node_count
  }

  node_config {
    service_account = data.google_client_openid_userinfo.current.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = merge(var.labels, {
      name       = local.node_pool_name
      managed_by = "terraform"
    })

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    machine_type = var.machine_type
    disk_size_gb = 300
    disk_type    = "pd-ssd"
  }
}

data "google_client_config" "provider" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.kubernetes.endpoint}"
  token                  = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.kubernetes.master_auth[0].cluster_ca_certificate)
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
    name     = data.google_client_openid_userinfo.current.email
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "random_string" "grafana_password" {
  length           = 8
  special          = false
}

data "google_dns_managed_zone" "dns_domain" {
  name = var.gcp_zone_name
}

locals {
  cluster_domain = trim("${var.name}.${data.google_dns_managed_zone.dns_domain.dns_name}", ".")
}

resource "google_dns_managed_zone" "subdomain_zone" {
  name        = replace(local.cluster_domain, ".", "-")
  dns_name    = "${local.cluster_domain}."
  description = "Managed zone for ${local.cluster_domain}"
}

resource "google_dns_record_set" "subdomain_ns_delegation" {
  name         = "${local.cluster_domain}."
  managed_zone = data.google_dns_managed_zone.dns_domain.name
  type         = "NS"
  ttl          = 300
  rrdatas      = google_dns_managed_zone.subdomain_zone.name_servers
}

provider "helm" {
  kubernetes = {
    host                   = "https://${google_container_cluster.kubernetes.endpoint}"
    token                  = data.google_client_config.provider.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.kubernetes.master_auth[0].cluster_ca_certificate)
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
      value = data.google_client_openid_userinfo.current.email
    }
  ]

  set_list = [
    {
      name  = "domainFilters"
      value = [local.cluster_domain]
    }
  ]

  depends_on = [google_dns_record_set.subdomain_ns_delegation]
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
      value = ["grafana.${local.cluster_domain}"]
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
