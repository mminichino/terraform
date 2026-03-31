#

output "grafana_admin_password" {
  value     = random_string.grafana_password.id
  sensitive = true
}

output "grafana_route_host" {
  value = local.grafana_route_host
}
