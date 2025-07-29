# Redis Enterprise Cluster

variable "environment" {
  type = string
}

variable "aws_key_pair" {
  type = string
}

variable "aws_vpc" {
  type = string
}

variable "dns_domain" {
  type = string
}

variable "access_key" {
  type = string
}

variable "secret_key" {
  type = string
}

variable "session_token" {
  type = string
}

variable "software" {
  type = string
}

module "redis-enterprise" {
  source = "./modules/redis"
  environment_name      = var.environment
  key_pair              = var.aws_key_pair
  vpc_id                = var.aws_vpc
  parent_domain         = var.dns_domain
  aws_access_key_id     = var.access_key
  aws_secret_access_key = var.secret_key
  aws_session_token     = var.session_token
  redis_distribution    = var.software
}
