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

variable "rdi" {
  type = string
}

variable "admin_password" {
  type = string
}

variable "redis_machine" {
  type = string
}

variable "client_machine" {
  type = string
}

variable "rdi_machine" {
  type = string
}

variable "rdi_nodes" {
  type = number
}

module "redis-enterprise" {
  source = "./modules/redis"
  environment_name      = var.environment
  parent_domain         = var.dns_domain
  aws_access_key_id     = var.access_key
  aws_secret_access_key = var.secret_key
  aws_session_token     = var.session_token
  redis_distribution    = var.software
  rdi_distribution      = var.rdi
  public_key_file       = var.public_key
  private_key_file      = var.private_key
  admin_password        = var.admin_password
  redis_machine_type    = var.redis_machine
  client_machine_type   = var.client_machine
  rdi_machine_type      = var.rdi_machine
  rdi_node_count        = var.rdi_nodes
}
