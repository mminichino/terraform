#

output "cluster_name" {
  description = "EKS cluster name."
  value       = module.cluster.cluster_name
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = module.cluster.cluster_arn
}

output "cluster_domain" {
  description = "Cluster DNS subdomain delegated under the parent hosted zone (same role as GKE cluster_domain)."
  value       = module.cluster.cluster_domain
}

output "cluster_hosted_zone_id" {
  description = "Route53 zone ID for cluster_domain (used to delegate ingress.* from eks_env)."
  value       = module.cluster.cluster_hosted_zone_id
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint (hostname)."
  value       = module.cluster.cluster_endpoint
}

output "cluster_endpoint_url" {
  description = "Kubernetes API server URL for provider configuration."
  value       = module.cluster.cluster_endpoint_url
}

output "cluster_ca_certificate" {
  description = "Base64-decoded cluster CA certificate for the Kubernetes provider."
  value       = module.cluster.cluster_ca_certificate
  sensitive   = true
}

output "cluster_ca_certificate_b64" {
  description = "PEM cluster CA certificate (base64) as returned by the EKS API."
  value       = module.cluster.cluster_ca_certificate_b64
  sensitive   = true
}

output "storage_class" {
  description = "Storage class name (declared on cluster); workloads use eks_env.eks_storage_class for the provisioned default."
  value       = var.storage_class_name
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for IRSA trust policies."
  value       = module.cluster.oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN for the cluster."
  value       = module.cluster.oidc_provider_arn
}

output "oidc_issuer_hostpath" {
  description = "OIDC issuer host/path without https:// for IAM condition keys."
  value       = module.cluster.oidc_issuer_hostpath
}

output "kubernetes_cluster_host" {
  description = "Kubernetes API host (alias of cluster_endpoint)."
  value       = module.cluster.kubernetes_cluster_host
}

output "exec_api_version" {
  value = module.cluster.exec_api_version
}

output "exec_command" {
  value = module.cluster.exec_command
}

output "exec_args" {
  value = module.cluster.exec_args
}

output "cluster" {
  description = "Cluster summary (aligned with OKE cluster output shape where useful)."
  value       = module.cluster.cluster
}

output "grafana_admin_password" {
  value     = module.eks_env.grafana_admin_password
  sensitive = true
}

output "grafana_hostname" {
  value = module.eks_env.grafana_hostname
}

output "grafana_ui" {
  value = module.eks_env.grafana_ui
}

output "ingress_ip" {
  value = module.eks_env.ingress_ip
}

output "nginx_ingress_ip" {
  description = "Alias for ingress_ip (matches gke_env output name)."
  value       = module.eks_env.nginx_ingress_ip
}

output "eks_domain_name" {
  value = module.eks_env.eks_domain_name
}

output "ingress_domain_name" {
  value = module.eks_env.ingress_domain_name
}

output "eks_storage_class" {
  value = module.eks_env.eks_storage_class
}
