#

terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
      version = "7.29.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "3.1.1"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "3.0.1"
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

provider "kubernetes" {
  host                   = module.oke.api_host
  cluster_ca_certificate = module.oke.cluster_ca_certificate

  exec {
    api_version = module.oke.exec_api_version
    command     = module.oke.exec_command
    args        = module.oke.exec_args
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.oke.api_host
    cluster_ca_certificate = module.oke.cluster_ca_certificate

    exec = {
      api_version = module.oke.exec_api_version
      command     = module.oke.exec_command
      args        = module.oke.exec_args
    }
  }
}

module "oke_env" {
  source           = "../../redis/oci/modules/oke_env"
  compartment_ocid = var.compartment_ocid
  domain_name      = var.domain_name
  region           = var.region
  tenancy_ocid     = var.tenancy_ocid
  vault_ocid       = var.vault_ocid
  cluster_ocid     = module.oke.cluster.ocid
}

module "redis_env" {
  source                      = "../../redis/oci/modules/redis_env"
  domain_name                 = var.domain_name
  namespace                   = var.name
  external_secret_cluster_key = var.cluster_key
  external_secret_redb_key    = var.redb_key
  external_secret_rdidb_key   = var.rdidb_key
  license                     = var.license
  depends_on                  = [module.oke_env]
}

module "argocd" {
  source      = "../../redis/oci/modules/argocd"
  domain_name = var.domain_name
}
