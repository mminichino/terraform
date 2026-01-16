#

output "grafana_admin_password" {
  value     = random_string.grafana_password.id
  sensitive = true
}

output "grafana_hostname" {
  value = local.grafana_hostname
}

output "grafana_ui" {
  value = "https://${local.grafana_hostname}"
}

output "domain_name" {
  value = var.domain_name
}
