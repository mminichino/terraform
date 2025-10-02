#

variable "gke_domain_name" {
  type = string
}

variable "namespace" {
  type    = string
  default = "redis"
}

variable "tls_secret" {
  type = string
  default = "redis-tls"
}

variable "operator_version" {
  type    = string
  default = "7.22.0-17"
}
