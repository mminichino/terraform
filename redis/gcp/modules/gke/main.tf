#

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

data "google_dns_managed_zone" "dns_domain" {
  name = var.gcp_zone_name
}

locals {
  cluster_domain = trim("${var.name}.${data.google_dns_managed_zone.dns_domain.dns_name}", ".")
}

resource "google_dns_managed_zone" "subdomain_zone" {
  name          = replace(local.cluster_domain, ".", "-")
  dns_name      = "${local.cluster_domain}."
  description   = "Managed zone for ${local.cluster_domain}"
  force_destroy = true
}

resource "google_dns_record_set" "subdomain_ns_delegation" {
  name         = "${local.cluster_domain}."
  managed_zone = data.google_dns_managed_zone.dns_domain.name
  type         = "NS"
  ttl          = 300
  rrdatas      = google_dns_managed_zone.subdomain_zone.name_servers
}
