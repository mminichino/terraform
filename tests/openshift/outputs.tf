#

output "grafana_password" {
  value     = module.grafana.grafana_admin_password
  sensitive = true
}

output "grafana_url" {
  value = "https://${module.grafana.grafana_route_host}"
}

output "cluster_url" {
  value = module.redis_env.cluster_url
}

output "cluster_password" {
  value     = module.redis_env.cluster_password
  sensitive = true
}

output "redb_password" {
  value     = module.redis_env.redb_password
  sensitive = true
}

output "rdidb_password" {
  value     = module.redis_env.rdidb_password
  sensitive = true
}

output "redb_endpoint" {
  value = "${module.redis_env.redb_lb_ip}:12000"
}

output "rdidb_endpoint" {
  value = "${module.redis_env.rdidb_lb_ip}:12001"
}
