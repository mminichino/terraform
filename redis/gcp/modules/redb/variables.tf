#

variable "name" {
  type = string
}

variable "kubernetes_endpoint" {
  type = string
}

variable "kubernetes_token" {
  type = string
}

variable "cluster_ca_certificate" {
  type = string
}

variable "credential_file" {
  type = string
}

variable "gcp_project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "gcp_region" {
  description = "The GCP region for the GKE cluster."
  type        = string
}

variable "namespace" {
  type    = string
  default = "redis"
}

variable "domain_name" {
  type = string
}

variable "cluster" {
  type = string
  default = "redis-enterprise-cluster"
}

variable "memory" {
  type    = string
  default = "1GB"
}

variable "replication" {
  type    = bool
  default = true
}

variable "shards" {
  type    = number
  default = 1
}

variable "placement" {
  type    = string
  default = "dense"
}

variable "port" {
  type    = number
  default = 12000
}

variable "eviction" {
  type    = string
  default = "noeviction"
}

variable "modules" {
  type    = list(string)
  default = ["ReJSON", "search", "timeseries"]
}
