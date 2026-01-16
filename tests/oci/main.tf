#

terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
      version = "7.29.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

module "vcn" {
  source           = "../../redis/oci/modules/vcn"
  compartment_ocid = var.compartment_ocid
  vcn_cidr         = var.vcn_cidr
  dns_label        = var.vcn_dns_label
  name             = var.name
}

module "oke" {
  source           = "../../redis/oci/modules/oke"
  name             = var.name
  compartment_ocid = var.compartment_ocid
  tenancy_ocid     = var.tenancy_ocid
  ssh_public_key   = var.ssh_public_key
  vcn_id           = module.vcn.vcn_id
  api_subnet_id    = module.vcn.api_subnet_id
  lb_subnet_id     = module.vcn.lb_subnet_id
  node_subnet_id   = module.vcn.node_subnet_id
  pod_subnet_id    = module.vcn.pod_subnet_id
}
