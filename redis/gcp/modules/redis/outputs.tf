#

output "node_private" {
  value = [google_compute_instance.redis_nodes.*.network_interface.0.network_ip]
}

output "node_public" {
  value = [google_compute_instance.redis_nodes.*.network_interface.0.access_config.0.nat_ip]
}

output "instance_hostnames" {
  value       = [for i in range(var.node_count) : "node${i + 1}.${local.cluster_domain}"]
}

output "admin_urls" {
  value       = [for i in range(var.node_count) : "https://node${i + 1}.${local.cluster_domain}:8443"]
}

output "primary_node_public_ip" {
  value = local.primary_node_public_ip
}

output "primary_node_private_ip" {
  value = local.primary_node_private_ip
}

output "api_public_base_url" {
  value = local.api_public_base_url
}

output "redis_machine_type" {
  value = var.machine_type
}

output "admin_user" {
  value = var.admin_user
}

output "password" {
  value = random_string.password.id
}
