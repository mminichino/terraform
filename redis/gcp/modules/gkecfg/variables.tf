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

variable "domain_name" {
  type = string
}

variable "service_account_email" {
  type = string
}
