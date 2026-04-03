#

variable "gcs_state_bucket" {
  type = string
}

variable "credential_file" {
  type = string
}

variable "name" {
  type        = string
  description = "Short environment name (VPC, EKS cluster, and DNS label cluster_domain = \"<name>.<parent>\"). Changing this replaces the cluster Route53 zone and eks_env. Use redis_kubernetes_namespace to name the Redis namespace without changing this."
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "cidr_block" {
  type    = string
  default = "10.82.0.0/16"
}

variable "parent_hosted_zone_id" {
  type        = string
  description = "Route53 hosted zone ID for the parent domain (must already exist; EKS creates a delegated subdomain for the cluster under that zone)."
}

variable "parent_domain_fqdn" {
  type        = string
  default     = null
  description = "Optional parent zone apex without trailing dot (e.g. demo.sa.example.com). When set, pins cluster DNS so it cannot drift from the Route53 data source; must match the zone for parent_hosted_zone_id."
}

variable "kubernetes_version" {
  type    = string
  default = "1.34"
}

variable "node_release_version" {
  description = "Kubernetes version for the cluster and managed node group."
  type        = string
  default     = "1.34.4-20260318"
}

variable "node_count" {
  type    = number
  default = 3
}

variable "eks_instance_types" {
  type    = list(string)
  default = ["m5.2xlarge"]
}

variable "eks_endpoint_public_access" {
  type    = bool
  default = true
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

variable "tags" {
  description = "Optional tags"
  type        = map(string)
  default     = {}
}
