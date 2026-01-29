#

variable "service_account_name" {
  type    = string
  default = "kubeconfig-sa"
}

variable "namespace" {
  type    = string
  default = "kube-system"
}

variable "cluster_role_binding_name" {
  type    = string
  default = "kubeconfig-sa-binding"
}

variable "service_account_token_secret" {
  type    = string
  default = "kubeconfig-sa-token"
}

variable "kubeconfig_filename" {
  type    = string
  default = "oke.kube.config"
}

variable "cluster_name" {
  type = string
}

variable "api_server" {
  type = string
}

variable "ca_data" {
  type = string
}
