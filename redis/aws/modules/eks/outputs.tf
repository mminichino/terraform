#

output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.kubernetes.name
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = aws_eks_cluster.kubernetes.arn
}

output "cluster_domain" {
  description = "Cluster DNS subdomain delegated under the parent hosted zone (same role as GKE cluster_domain)."
  value       = local.cluster_domain
}

output "cluster_hosted_zone_id" {
  description = "Route53 zone ID for cluster_domain (used to delegate ingress.* from eks_env)."
  value       = aws_route53_zone.cluster.zone_id
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint (hostname)."
  value       = aws_eks_cluster.kubernetes.endpoint
}

output "cluster_endpoint_url" {
  description = "Kubernetes API server URL for provider configuration."
  value       = aws_eks_cluster.kubernetes.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-decoded cluster CA certificate for the Kubernetes provider."
  value       = base64decode(aws_eks_cluster.kubernetes.certificate_authority[0].data)
  sensitive   = true
}

output "cluster_ca_certificate_b64" {
  description = "PEM cluster CA certificate (base64) as returned by the EKS API."
  value       = aws_eks_cluster.kubernetes.certificate_authority[0].data
  sensitive   = true
}

output "storage_class" {
  description = "Storage class name to pass to redis_env / eks_env."
  value       = var.storage_class_name
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for IRSA trust policies."
  # noinspection HILUnresolvedReference
  value       = aws_eks_cluster.kubernetes.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN for the cluster."
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_issuer_hostpath" {
  description = "OIDC issuer host/path without https:// for IAM condition keys."
  value       = local.oidc_issuer_hostpath
}

output "kubernetes_cluster_host" {
  description = "Kubernetes API host (alias of cluster_endpoint)."
  value       = aws_eks_cluster.kubernetes.endpoint
}

output "exec_api_version" {
  value = "client.authentication.k8s.io/v1beta1"
}

output "exec_command" {
  value = "aws"
}

output "exec_args" {
  value = ["eks", "get-token", "--cluster-name", aws_eks_cluster.kubernetes.name, "--region", var.aws_region]
}

output "cluster" {
  description = "Cluster summary (aligned with OKE cluster output shape where useful)."
  value = {
    name = aws_eks_cluster.kubernetes.name
    arn  = aws_eks_cluster.kubernetes.arn
  }
}
