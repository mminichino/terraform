provider "google" {
  credentials = file(var.credential_file)
  project     = var.gcp_project_id
  region      = var.gcp_region
}

resource "google_compute_network" "vpc" {
  name                    = var.name
  auto_create_subnetworks = "false"
  project                 = var.gcp_project_id
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = "${var.name}-subnet"
  ip_cidr_range = var.cidr_block
  network       = google_compute_network.vpc.id
  region        = var.gcp_region
  project       = var.gcp_project_id
}

resource "google_compute_firewall" "allow_ssh_iap" {
  name    = "${var.name}-allow-ssh-iap"
  network = google_compute_network.vpc.name
  project = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # This is the IP range for IAP
  target_tags   = ["ssh-iap"]
}
