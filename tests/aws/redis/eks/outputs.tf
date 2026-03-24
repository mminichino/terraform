#

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "subnet_ids" {
  value = module.vpc.subnet_id_list
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_domain" {
  value = module.eks.cluster_domain
}

output "cluster_ui" {
  description = "Redis cluster admin UI"
  value       = module.redis_env.cluster_url
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = module.eks_env.grafana_admin_password
  sensitive   = true
}

output "grafana_ui" {
  description = "Grafana UI URL"
  value       = module.eks_env.grafana_ui
}

output "ingress_domain_name" {
  value = module.eks_env.ingress_domain_name
}
