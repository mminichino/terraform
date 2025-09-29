#

resource "google_compute_network" "vpc" {
  name                    = var.name
  auto_create_subnetworks = "false"
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
