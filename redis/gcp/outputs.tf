#

output "client_node_private_ips" {
  description = "Private IP addresses of Client nodes"
  value       = module.client.client_private_ips
}

output "client_node_public_ips" {
  description = "Public IP addresses of Client nodes"
  value       = module.client.client_public_ips
}
