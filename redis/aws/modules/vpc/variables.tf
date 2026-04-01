#

variable "name" {
  description = "Deployment name"
}

variable "aws_region" {
  description = "AWS region"
  default = "us-east-2"
}

variable "cidr_block" {
  description = "VPC CIDR"
  default = "10.55.0.0/16"
}

variable "tags" {
  description = "Optional tags"
  type        = map(string)
  default     = {}
}

variable "eks_cluster_name" {
  description = "Override EKS cluster name for subnet discovery tags (kubernetes.io/cluster/<name>=shared and kubernetes.io/role/elb=1). When null (default), uses the module name input plus the suffix \"-eks\"."
  type        = string
  default     = null
}
