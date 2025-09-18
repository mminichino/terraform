#

output "grafana_admin_password" {
  value = random_string.grafana_password.id
}
