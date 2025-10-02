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

output "nginx_ingress_ip" {
  value = local.nginx_ingress_ip
}

output "gke_domain_name" {
  value = var.gke_domain_name
}

output "gke_storage_class" {
  value = var.gke_storage_class
}
