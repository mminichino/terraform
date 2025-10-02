#

output "argocd_hostname" {
  value = local.argocd_hostname
}

output "argocd_ui" {
  value = "https://${local.argocd_hostname}"
}
