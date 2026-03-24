#

variable "eks_domain_name" {
  description = "Cluster DNS name (same as module.eks.cluster_domain)."
  type        = string
}

variable "eks_storage_class" {
  description = "Storage class name to pass to redis_env (same as module.eks.storage_class)."
  type        = string
}

variable "cluster_hosted_zone_id" {
  description = "Route53 hosted zone ID for eks_domain_name (delegates ingress.*)."
  type        = string
}

variable "aws_region" {
  description = "AWS region (for external-dns and Secrets Manager)."
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN for IRSA trust policies."
  type        = string
}

variable "oidc_issuer_hostpath" {
  description = "OIDC issuer URL without https:// (IAM condition key prefix)."
  type        = string
}

variable "external_dns_chart_version" {
  type    = string
  default = "1.15.0"
}
