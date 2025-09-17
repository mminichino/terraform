#

variable "domain_name" {
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

variable "namespace" {
  type    = string
  default = "redis"
}

variable "cpu" {
  type = string
  default = "4"
}

variable "memory" {
  type = string
  default = "8Gi"
}

variable "mode_count" {
  type = number
  default = 3
}

variable "storage_class" {
  type    = string
  default = "standard"
}
