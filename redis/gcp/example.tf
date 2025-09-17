#

variable "name" {
  type = string
}

variable "credential_file" {
  type = string
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "gke_domain" {
  type = string
}

variable "public_key" {
  type = string
}

module "vpc" {
  source                = "./modules/vpc"
  name                  = "usc1-${var.name}"
  cidr_block            = "10.99.0.0/16"
  credential_file       = var.credential_file
  gcp_project_id        = var.project
  gcp_region            = var.region
}

module "gke" {
  source                = "./modules/gke"
  name                  = "usc1-${var.name}"
  credential_file       = var.credential_file
  gcp_project_id        = var.project
  gcp_region            = var.region
  network_name          = module.vpc.vpc_name
  subnet_name           = module.vpc.subnet_name
  gcp_zone_name         = var.gke_domain
}

module "client" {
  source                = "./modules/client"
  name                  = "usc1-${var.name}"
  credential_file       = var.credential_file
  gcp_project_id        = var.project
  gcp_region            = var.region
  network_name          = module.vpc.vpc_name
  subnet_name           = module.vpc.subnet_name
  public_key_file       = var.public_key
}
