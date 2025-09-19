#

output "client_node_private_ips" {
  description = "Private IP addresses of Client nodes"
  value       = module.client.client_private_ips
}

output "client_node_public_ips" {
  description = "Public IP addresses of Client nodes"
  value       = module.client.client_public_ips
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = module.gke_env.grafana_admin_password
  sensitive   = true
}

output "database_password" {
  description = "Redis Database password"
  value       = module.redb.database_password
  sensitive   = true
}

output "cluster_password" {
  description = "Redis Cluster password"
  value       = module.rec.cluster_password
  sensitive   = true
}
