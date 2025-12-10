#

resource "google_compute_network" "vpc" {
  name                    = var.name
  auto_create_subnetworks = false
  project                 = var.gcp_project_id

  provisioner "local-exec" {
    when    = destroy
    command = "for RULE in $(gcloud compute firewall-rules list --filter=\"network:${self.name}\" --project=${self.project} --format=\"value(name)\"); do gcloud compute firewall-rules delete \"$RULE\" --project=${self.project} -q ; done"
  }
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = "${var.name}-subnet"
  ip_cidr_range = var.cidr_block
  network       = google_compute_network.vpc.id
  region        = var.gcp_region
  project       = var.gcp_project_id

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = var.services_range
  }

  secondary_ip_range {
    range_name    = "pod-range"
    ip_cidr_range = var.pod_range
  }
}

resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "${var.name}-allow-ssh-iap"
  network = google_compute_network.vpc.name
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["ssh-iap"]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "${var.name}-allow-internal"
  network = google_compute_network.vpc.name
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.cidr_block]
  destination_ranges = [var.pod_range]
  direction = "INGRESS"
  priority = 1000
}

resource "google_compute_firewall" "allow_secondary" {
  name    = "${var.name}-allow-secondary"
  network = google_compute_network.vpc.name
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.pod_range]
  destination_ranges = [var.cidr_block]
  direction = "INGRESS"
  priority = 1000
}

resource "google_compute_firewall" "allow_primary" {
  name    = "${var.name}-allow-primary"
  network = google_compute_network.vpc.name
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.cidr_block]
  destination_ranges = [var.cidr_block]
  direction = "INGRESS"
  priority = 1000
}
