#

variable "name" {
  description = "Name prefix for the EKS cluster and related resources."
  type        = string
  default     = "eks-cluster"
}

variable "aws_region" {
  description = "AWS region for the EKS cluster."
  type        = string
}

variable "parent_hosted_zone_id" {
  description = "Route53 hosted zone ID for the parent domain (delegates a subdomain for this cluster, matching the GKE DNS pattern)."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS control plane and worker nodes (typically public subnets from the VPC module)."
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster and managed node group."
  type        = string
  default     = "1.34"
}

variable "node_count" {
  description = "Desired capacity for the managed node group."
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum size for the managed node group."
  type        = number
  default     = 3
}

variable "min_node_count" {
  description = "Minimum size for the managed node group."
  type        = number
  default     = 1
}

variable "instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["m5.xlarge"]
}

variable "storage_class_name" {
  description = "Default storage class name passed through to env modules (matches the EKS default gp2 unless you install another StorageClass)."
  type        = string
  default     = "gp2"
}

variable "endpoint_public_access" {
  description = "Whether the Kubernetes API server endpoint is publicly reachable."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to taggable resources."
  type        = map(string)
  default     = {}
}
