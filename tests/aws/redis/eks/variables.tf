#

variable "name" {
  type        = string
  description = "Short environment name (used for VPC, EKS, and redis namespace)."
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "parent_hosted_zone_id" {
  type        = string
  description = "Route53 hosted zone ID for the parent domain (must already exist; EKS creates a delegated subdomain for the cluster under that zone)."
}

variable "kubernetes_version" {
  type    = string
  default = "1.31"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "max_node_count" {
  type    = number
  default = 3
}

variable "min_node_count" {
  type    = number
  default = 1
}

variable "eks_instance_types" {
  type    = list(string)
  default = ["m5.xlarge"]
}

variable "eks_storage_class_name" {
  type    = string
  default = "gp2"
}

variable "eks_endpoint_public_access" {
  type    = bool
  default = true
}

variable "external_dns_chart_version" {
  type    = string
  default = "1.15.0"
}

variable "cluster_key" {
  type = string
}

variable "redb_key" {
  type = string
}

variable "rdidb_key" {
  type = string
}

variable "license" {
  type    = string
  default = ""
}
