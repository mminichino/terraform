output "vcn_id" {
  value = module.vcn.vcn_id
}

output "public_subnet_id" {
  value = module.vcn.public_subnet_id
}

output "private_subnet_id" {
  value = module.vcn.private_subnet_id
}

output "kubeconfig" {
  value = module.oke.cluster.kubeconfig
}

output "cluster_ui" {
  description = "Redis cluster admin UI"
  value       = module.redis_env.cluster_url
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = module.oke_env.grafana_admin_password
  sensitive   = true
}

output "argocd_password" {
  description = "ArgoCD Admin Password"
  value       = module.argocd.admin_password
  sensitive   = true
}

output "grafana_ui" {
  description = "Grafana UI URL"
  value       = module.oke_env.grafana_ui
}

output "argocd_ui" {
  description = "ArgoCD UI URL"
  value       = module.argocd.argocd_ui
}
