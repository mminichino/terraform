#

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

data "google_client_openid_userinfo" "current" {}

data "google_compute_zones" "available" {
  region = var.gcp_region
}

resource "google_compute_firewall" "client_firewall" {
  name    = "${var.name}-client-firewall"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

locals {
  ssh_key_file = "~/.ssh/${var.public_key_file}"
}

resource "google_compute_instance" "client_nodes" {
  count        = var.node_count
  name         = "${var.name}-client-${count.index + 1}"
  machine_type = var.machine_type
  zone         = data.google_compute_zones.available.names[count.index % length(data.google_compute_zones.available.names)]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.root_volume_size
    }
  }

  network_interface {
    subnetwork = var.subnet_name
    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    ssh-keys       = "${var.gcp_user}:${file(local.ssh_key_file)}"
    startup-script = file("${path.module}/scripts/client.sh")
  }

  service_account {
    email  = data.google_client_openid_userinfo.current.email
    scopes = ["cloud-platform"]
  }

  tags = ["${var.name}-client"]

  labels = merge(var.labels, {
    name       = "${var.name}-client-${count.index + 1}"
    managed_by = "terraform"
  })
}
