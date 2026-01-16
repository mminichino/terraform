#

output "argocd_hostname" {
  value = local.argocd_hostname
}

output "argocd_ui" {
  value = "https://${local.argocd_hostname}"
}

output "admin_password" {
  value     = data.kubernetes_secret_v1.argocd_admin_password.data["password"]
  sensitive = true
}
