#

variable "gcs_state_bucket" {
  type = string
}

variable "credential_file" {
  type = string
}

variable "name" {}
variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "compartment_ocid" {}
variable "compartment_name" {}
variable "vcn_cidr" {}
variable "vcn_dns_label" {}
variable "ssh_public_key" {}
variable "domain_name" {}
variable "vault_ocid" {}
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
  type = string
  default = ""
}
