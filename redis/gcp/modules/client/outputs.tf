#

output "client_public_ips" {
  description = "Public IP addresses of the client nodes"
  value       = google_compute_instance.client_nodes.*.network_interface.0.access_config.0.nat_ip
}

output "client_private_ips" {
  description = "Private IP addresses of the client nodes"
  value       = google_compute_instance.client_nodes.*.network_interface.0.network_ip
}
