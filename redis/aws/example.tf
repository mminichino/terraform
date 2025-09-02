# Redis Enterprise Cluster

variable "environment" {
  type = string
}

variable "dns_domain" {
  type = string
}

variable "public_key" {
  type = string
}

variable "private_key" {
  type = string
}

variable "software" {
  type = string
}

variable "rdi" {
  type = string
}

variable "admin_password" {
  type = string
}

variable "redis_machine" {
  type = string
}

variable "redis_nodes" {
  type    = number
  default = 3
}

variable "client_machine" {
  type = string
}

variable "client_nodes" {
  type    = number
  default = 1
}

variable "rdi_machine" {
  type = string
}

variable "rdi_nodes" {
  type    = number
  default = 0
}

variable "ec2_role" {
  type = string
}

module "environment" {
  source                = "./modules/env"
  environment_name      = var.environment
  public_key_file       = var.public_key
}

module "vpc" {
  source                = "./modules/vpc"
  name_prefix           = module.environment.name_prefix
  aws_region            = module.environment.aws_region
}

module "redis" {
  source                = "./modules/redis"
  environment_name      = module.environment.environment_name
  environment_id        = module.environment.environment_id
  name_prefix           = module.environment.name_prefix
  aws_region            = module.environment.aws_region
  aws_subnet_id_list    = module.vpc.subnet_id_list
  aws_vpc_cidr          = module.vpc.vpc_cidr
  aws_vpc_id            = module.vpc.vpc_id
  aws_key_name          = module.environment.aws_ssh_key_name
  node_count            = var.redis_nodes
  parent_domain         = var.dns_domain
  ec2_instance_role     = var.ec2_role
  redis_distribution    = var.software
  private_key_file      = var.private_key
  admin_password        = var.admin_password
  redis_machine_type    = var.redis_machine
}

module "client" {
  source                = "./modules/client"
  environment_name      = module.environment.environment_name
  name_prefix           = module.environment.name_prefix
  aws_region            = module.environment.aws_region
  aws_subnet_id_list    = module.vpc.subnet_id_list
  aws_vpc_cidr          = module.vpc.vpc_cidr
  aws_vpc_id            = module.vpc.vpc_id
  aws_key_name          = module.environment.aws_ssh_key_name
  client_count          = var.client_nodes
  ec2_instance_role     = var.ec2_role
  client_machine_type   = var.client_machine
}

module "rdi" {
  source                = "./modules/rdi"
  environment_name      = module.environment.environment_name
  name_prefix           = module.environment.name_prefix
  aws_region            = module.environment.aws_region
  aws_subnet_id_list    = module.vpc.subnet_id_list
  aws_vpc_cidr          = module.vpc.vpc_cidr
  aws_vpc_id            = module.vpc.vpc_id
  aws_key_name          = module.environment.aws_ssh_key_name
  rdi_node_count        = var.rdi_nodes
  ec2_instance_role     = var.ec2_role
  rdi_machine_type      = var.rdi_machine
  rdi_distribution      = var.rdi
}
