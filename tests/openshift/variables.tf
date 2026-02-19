#

variable "gcs_state_bucket" {
  type = string
}

variable "credential_file" {
  type = string
}

variable "config_context" {
  type    = string
  default = "admin"
}

variable "name" {}
variable "region" {}
variable "ssh_public_key" {}
variable "domain_name" {}

variable "license" {
  type = string
  default = ""
}
