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

variable "redis_machine" {
  type = string
}

variable "redis_nodes" {
  type    = number
  default = 3
}

variable "admin_user" {
  type    = string
  default = "admin@redis.com"
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

variable "rdbms_machine" {
  type = string
}

variable "rdbms_nodes" {
  type = number
}

variable "ec2_role" {
  type = string
}

variable "deploy_redis" {
  type = bool
  default = false
}

variable "deploy_rdbms" {
  type = bool
  default = false
}

variable "deploy_client" {
  type = bool
  default = false
}

variable "deploy_rdi" {
  type = bool
  default = false
}

module "vpc" {
  source                = "./modules/vpc"
  name                  = "use2-dev"
  cidr_block            = "10.99.0.0/16"
}

module "redis" {
  source                = "./modules/redis"
  name                  = "use2-dev-redis"
  aws_region            = module.vpc.aws_region
  aws_subnet_id_list    = module.vpc.subnet_id_list
  aws_vpc_cidr          = module.vpc.vpc_cidr
  aws_vpc_id            = module.vpc.vpc_id
  admin_user            = var.admin_user
  node_count            = var.deploy_redis ? 3 : 0
  parent_domain         = var.dns_domain
  ec2_instance_role     = var.ec2_role
  redis_distribution    = var.software
  private_key_file      = var.private_key
  redis_machine_type    = var.redis_machine
  public_key_file       = var.public_key
}

module "rdbms" {
  source                = "./modules/rdbms"
  name                  = "use2-dev-rdbms"
  aws_region            = module.vpc.aws_region
  aws_subnet_id_list    = module.vpc.subnet_id_list
  aws_vpc_cidr          = module.vpc.vpc_cidr
  aws_vpc_id            = module.vpc.vpc_id
  node_count            = var.deploy_rdbms ? 1 : 0
  ec2_instance_role     = var.ec2_role
  machine_type          = var.rdbms_machine
  public_key_file       = var.public_key
}

module "database" {
  count                 = var.deploy_redis ? 1 : 0
  source                = "./modules/database"
  password              = module.redis.password
  username              = module.redis.admin_user
  private_key_file      = var.private_key
  public_ip             = module.redis.primary_node_public_ip
  depends_on            = [module.redis]
}

module "client" {
  source                = "./modules/client"
  name                  = "use2-dev-client"
  aws_region            = module.vpc.aws_region
  aws_subnet_id_list    = module.vpc.subnet_id_list
  aws_vpc_cidr          = module.vpc.vpc_cidr
  aws_vpc_id            = module.vpc.vpc_id
  client_count          = var.deploy_client ? 1 : 0
  ec2_instance_role     = var.ec2_role
  client_machine_type   = var.client_machine
  public_key_file       = var.public_key
}

module "rdi" {
  source                = "./modules/rdi"
  name                  = "use2-dev-rdi"
  aws_region            = module.vpc.aws_region
  aws_subnet_id_list    = module.vpc.subnet_id_list
  aws_vpc_cidr          = module.vpc.vpc_cidr
  aws_vpc_id            = module.vpc.vpc_id
  rdi_node_count        = var.deploy_rdi ? 1 : 0
  ec2_instance_role     = var.ec2_role
  rdi_machine_type      = var.rdi_machine
  rdi_distribution      = var.rdi
  public_key_file       = var.public_key
}
