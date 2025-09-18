#

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
