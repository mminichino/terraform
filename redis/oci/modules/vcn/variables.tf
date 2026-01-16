#

variable "name" {
  type = string
}

variable "compartment_ocid" {
  type = string
}

variable "vcn_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "dns_label" {
  type    = string
  default = "vcn1"
}
