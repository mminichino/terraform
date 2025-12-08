#

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source                = "../../../redis/aws/modules/vpc"
  name                  = "usc1-${var.name}"
  cidr_block            = "10.81.0.0/16"
}

module "redis" {
  source                = "../../../redis/aws/modules/redis"
  name                  = "usc1-${var.name}"
  private_key_file      = var.private_key
  public_key_file       = var.public_key
  bucket                = var.bucket
  software_version      = var.software_version
  ec2_instance_role     = var.ec2_role
  parent_domain         = var.dns_domain
  aws_subnet_id_list    = module.vpc.subnet_id_list
  aws_vpc_cidr          = module.vpc.vpc_cidr
  aws_vpc_id            = module.vpc.vpc_id
  depends_on            = [module.vpc]
}
