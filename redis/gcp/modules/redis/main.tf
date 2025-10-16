terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }
  }
}
#

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

data "google_client_openid_userinfo" "current" {}

data "google_compute_zones" "available" {
  region = var.gcp_region
}

data "google_dns_managed_zone" "dns_domain" {
  name = var.gcp_zone_name
}

locals {
  cluster_domain = trim("${var.name}.${data.google_dns_managed_zone.dns_domain.dns_name}", ".")
}

resource "random_string" "password" {
  length           = 8
  special          = false
}

resource "google_compute_firewall" "redis_firewall" {
  name    = "${var.name}-redis-firewall"
  network = var.network_name

  allow {
    protocol = "tcp"
    ports    = ["22", "53", "6379", "16379", "8443", "9443", "10000-19999"]
  }

  allow {
    protocol = "udp"
    ports    = ["53"]
  }

  source_ranges = ["0.0.0.0/0"]
}

locals {
  ssh_key_file = "~/.ssh/${var.public_key_file}"
  ssh_private_key_file = "~/.ssh/${var.private_key_file}"
}

resource "google_compute_disk" "data" {
  count = var.node_count
  name  = "${var.name}-disk-data-${count.index + 1}"
  type  = "pd-ssd"
  zone  = data.google_compute_zones.available.names[count.index % length(data.google_compute_zones.available.names)]
  size  = var.data_volume_size
}

resource "google_compute_instance" "redis_nodes" {
  count        = var.node_count
  name         = "${var.name}-redis-${count.index + 1}"
  machine_type = var.machine_type
  zone         = data.google_compute_zones.available.names[count.index % length(data.google_compute_zones.available.names)]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.root_volume_size
    }
  }

  attached_disk {
    source      = google_compute_disk.data[count.index].self_link
    device_name = "data-disk-b"
    mode        = "READ_WRITE"
  }

  network_interface {
    subnetwork = var.subnet_name
    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    ssh-keys       = "${var.gcp_user}:${file(local.ssh_key_file)}"
    startup-script = templatefile("${path.module}/scripts/redis.sh", {
      redis_distribution = var.redis_distribution
    })
  }

  service_account {
    email  = data.google_client_openid_userinfo.current.email
    scopes = ["cloud-platform"]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(local.ssh_private_key_file)
    host        = self.network_interface[0].access_config[0].nat_ip
  }

  provisioner "remote-exec" {
    inline = [
      "until [ -f /etc/default/.host_init_complete ]; do sleep 5; done",
    ]
  }

  tags = ["${var.name}-redis"]

  labels = merge(var.labels, {
    name       = "${var.name}-redis-${count.index + 1}"
    managed_by = "terraform"
  })
}

resource "google_dns_record_set" "host_records" {
  count        = var.node_count
  managed_zone = var.gcp_zone_name
  name         = "node${count.index + 1}.${local.cluster_domain}."
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_instance.redis_nodes[count.index].network_interface[0].access_config[0].nat_ip]
  depends_on   = [google_compute_instance.redis_nodes]
}

resource "google_dns_record_set" "ns_record" {
  count        = var.node_count > 0 ? 1 : 0
  managed_zone = var.gcp_zone_name
  name         = "${local.cluster_domain}."
  type         = "NS"
  ttl          = 300
  rrdatas      = [for i in range(var.node_count) : "node${i + 1}.${local.cluster_domain}."]
  depends_on   = [google_compute_instance.redis_nodes]
}

locals {
  primary_node_private_ip = var.node_count > 0 ? google_compute_instance.redis_nodes[0].network_interface[0].network_ip : null
  primary_node_public_ip = var.node_count > 0 ? google_compute_instance.redis_nodes[0].network_interface[0].access_config[0].nat_ip : null
  api_public_base_url = var.node_count > 0 ? "https://${google_compute_instance.redis_nodes[0].network_interface[0].access_config[0].nat_ip}:9443" : null
}

resource "null_resource" "create_cluster" {
  count = var.node_count > 0 ? 1 : 0

  triggers = {
    node_ids = join(",", google_compute_instance.redis_nodes.*.id)
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(local.ssh_private_key_file)
    host        = google_compute_instance.redis_nodes[count.index].network_interface[0].access_config[0].nat_ip
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/create_cluster.sh", {
      cluster_name = var.name
      domain_name  = local.cluster_domain
      admin_user   = var.admin_user
      password     = random_string.password.id
    })
    destination = "/tmp/create_cluster.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/create_cluster.sh",
      "/tmp/create_cluster.sh"
    ]
  }

  depends_on = [google_dns_record_set.ns_record, google_dns_record_set.host_records]
}

resource "null_resource" "join_cluster" {
  count = max(0, var.node_count - 1)

  triggers = {
    node_id = google_compute_instance.redis_nodes[count.index + 1].id
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(local.ssh_private_key_file)
    host        = google_compute_instance.redis_nodes[count.index + 1].network_interface[0].access_config[0].nat_ip
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/join_cluster.sh", {
      primary_node = local.primary_node_private_ip
      domain_name  = local.cluster_domain
      admin_user   = var.admin_user
      password     = random_string.password.id
    })
    destination = "/tmp/join_cluster.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/join_cluster.sh",
      "/tmp/join_cluster.sh"
    ]
  }

  depends_on = [null_resource.create_cluster]
}
