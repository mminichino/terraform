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

output "ingress_ip" {
  value = coalesce(local.ingress_lb_ip, local.ingress_lb_hostname)
}

output "nginx_ingress_ip" {
  description = "Alias for ingress_ip (matches gke_env output name)."
  value       = coalesce(local.ingress_lb_ip, local.ingress_lb_hostname)
}

output "eks_domain_name" {
  value = var.eks_domain_name
}

output "ingress_domain_name" {
  value = local.ingress_dns_name
}

output "eks_storage_class" {
  description = "Default gp3 StorageClass created by this module (EBS CSI)."
  value       = kubernetes_storage_class_v1.gp3.metadata[0].name
}
