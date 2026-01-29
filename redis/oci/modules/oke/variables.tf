#

variable "name" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "v1.34.1"
}

variable "tenancy_ocid" {
  type = string
}

variable "compartment_ocid" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "vcn_id" {
  type = string
}

variable "api_subnet_id" {
  type = string
}

variable "lb_subnet_id" {
  type = string
}

variable "node_subnet_id" {
  type = string
}

variable "pod_subnet_id" {
  type = string
}
