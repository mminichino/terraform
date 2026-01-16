#

locals {
  public_cidr  = cidrsubnet(var.vcn_cidr, 8, 1)
  private_cidr = cidrsubnet(var.vcn_cidr, 8, 2)
  api_cidr     = cidrsubnet(var.vcn_cidr, 8, 10)
  lb_cidr      = cidrsubnet(var.vcn_cidr, 8, 20)
  node_cidr    = cidrsubnet(var.vcn_cidr, 8, 30)
  pod_cidr     = cidrsubnet(var.vcn_cidr, 6, 10)
}

data "oci_core_services" "all" {}

resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = [var.vcn_cidr]
  display_name   = "${var.name}-vcn"
  dns_label      = var.dns_label
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-igw"
  enabled        = true
}

resource "oci_core_nat_gateway" "nat" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-nat"
}

resource "oci_core_service_gateway" "sgw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-sgw"

  services {
    service_id = data.oci_core_services.all.services[0].id
  }
}

resource "oci_core_route_table" "public_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_route_table" "private_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-private-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat.id
  }

  route_rules {
    destination_type  = "SERVICE_CIDR_BLOCK"
    destination       = data.oci_core_services.all.services[0].cidr_block
    network_entity_id = oci_core_service_gateway.sgw.id
  }
}

resource "oci_core_security_list" "public_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-public-sl"

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    protocol    = "all"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "private_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-private-sl"

  ingress_security_rules {
    protocol    = "all"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "api_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-api-sl"

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    protocol    = "all"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "lb_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-lb-sl"

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
      min = 443
      max = 443
    }
  }

  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "nodes_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${var.name}-nodes-sl"

  ingress_security_rules {
    protocol    = "all"
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }
}

resource "oci_core_subnet" "public" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.this.id
  display_name               = "${var.name}-public-subnet"
  cidr_block                 = local.public_cidr
  route_table_id             = oci_core_route_table.public_rt.id
  prohibit_public_ip_on_vnic = false
  dns_label                  = "public"
  security_list_ids          = [oci_core_security_list.public_sl.id]
}

resource "oci_core_subnet" "private" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.this.id
  display_name               = "${var.name}-private-subnet"
  cidr_block                 = local.private_cidr
  route_table_id             = oci_core_route_table.private_rt.id
  prohibit_public_ip_on_vnic = true
  dns_label                  = "private"
  security_list_ids          = [oci_core_security_list.private_sl.id]
}

resource "oci_core_subnet" "api_endpoint_subnet" {
  compartment_id               = var.compartment_ocid
  vcn_id                       = oci_core_vcn.this.id
  display_name                 = "${var.name}-api-subnet"
  cidr_block                   = local.api_cidr
  route_table_id               = oci_core_route_table.public_rt.id
  prohibit_public_ip_on_vnic   = false
  dns_label                    = "api"
  security_list_ids            = [oci_core_security_list.api_sl.id]
}

resource "oci_core_subnet" "lb_subnet" {
  compartment_id               = var.compartment_ocid
  vcn_id                       = oci_core_vcn.this.id
  display_name                 = "${var.name}-lb-subnet"
  cidr_block                   = local.lb_cidr
  route_table_id               = oci_core_route_table.public_rt.id
  prohibit_public_ip_on_vnic   = false
  dns_label                    = "lb"
  security_list_ids            = [oci_core_security_list.lb_sl.id]
}

resource "oci_core_subnet" "nodes_subnet" {
  compartment_id               = var.compartment_ocid
  vcn_id                       = oci_core_vcn.this.id
  display_name                 = "${var.name}-nodes-subnet"
  cidr_block                   = local.node_cidr
  route_table_id               = oci_core_route_table.private_rt.id
  prohibit_public_ip_on_vnic   = true
  dns_label                    = "node"
  security_list_ids            = [oci_core_security_list.nodes_sl.id]
}

resource "oci_core_subnet" "pods_subnet" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.this.id
  display_name               = "${var.name}-pods-subnet"
  cidr_block                 = local.pod_cidr
  route_table_id             = oci_core_route_table.private_rt.id
  prohibit_public_ip_on_vnic = true
  dns_label                  = "pod"
  security_list_ids          = [oci_core_security_list.nodes_sl.id]
}
