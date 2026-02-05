#

variable "namespace" {
  type    = string
  default = "argocd"
}

variable "argocd_config_version" {
  type    = string
  default = "0.1.0"
}

variable "repository" {
  type = string
}

variable "external_secret_store" {
  type = string
}

variable "external_secret_key" {
  type = string
}
