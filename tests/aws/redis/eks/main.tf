#

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source     = "../../../../redis/aws/modules/vpc"
  name       = var.name
  aws_region = var.aws_region
  cidr_block = var.cidr_block
  tags       = var.tags
}

module "eks" {
  source                      = "../../../../redis/aws/modules/eks"
  name                        = var.name
  aws_region                  = var.aws_region
  cluster_admin_principal_arn = data.aws_caller_identity.current.arn
  parent_hosted_zone_id       = var.parent_hosted_zone_id
  parent_domain_fqdn          = var.parent_domain_fqdn
  subnet_ids                  = module.vpc.subnet_id_list
  kubernetes_version          = var.kubernetes_version
  node_release_version        = var.node_release_version
  node_count                  = var.node_count
  instance_types              = var.eks_instance_types
  endpoint_public_access      = var.eks_endpoint_public_access
  tags                        = var.tags
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint_url
  cluster_ca_certificate = module.eks.cluster_ca_certificate

  exec {
    api_version = module.eks.exec_api_version
    command     = module.eks.exec_command
    args        = module.eks.exec_args
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint_url
    cluster_ca_certificate = module.eks.cluster_ca_certificate

    exec = {
      api_version = module.eks.exec_api_version
      command     = module.eks.exec_command
      args        = module.eks.exec_args
    }
  }
}

module "redis_env" {
  source                      = "../../../../redis/aws/modules/redis_env"
  domain_name                 = module.eks.eks_domain_name
  namespace                   = var.name
  external_secret_cluster_key = var.cluster_key
  external_secret_redb_key    = var.redb_key
  external_secret_rdidb_key   = var.rdidb_key
  license                     = var.license
  storage_class               = module.eks.eks_storage_class
  depends_on                  = [module.eks]
}
