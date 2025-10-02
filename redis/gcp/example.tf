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

variable "rec_service_type" {
  type    = string
  default = "nginx"
}

provider "google" {
  credentials = file(var.credential_file)
  project     = var.project
  region      = var.region
}

module "vpc" {
  source                = "./modules/vpc"
  name                  = "usc1-${var.name}"
  cidr_block            = "10.99.0.0/16"
  gcp_project_id        = var.project
  gcp_region            = var.region
}

module "gke" {
  source                = "./modules/gke"
  name                  = "usc1-${var.name}"
  gcp_project_id        = module.vpc.gcp_project_id
  gcp_region            = module.vpc.gcp_region
  network_name          = module.vpc.vpc_name
  subnet_name           = module.vpc.subnet_name
  gcp_zone_name         = var.gke_domain
  depends_on            = [module.vpc]
}

provider "helm" {
  kubernetes = {
    host                   = module.gke.cluster_endpoint_url
    token                  = module.gke.access_token
    cluster_ca_certificate = module.gke.cluster_ca_certificate
  }
}

provider "kubernetes" {
  host                   = module.gke.cluster_endpoint_url
  token                  = module.gke.access_token
  cluster_ca_certificate = module.gke.cluster_ca_certificate
}

module "gke_env" {
  source                 = "./modules/gke_env"
  gke_domain_name        = module.gke.cluster_domain
  gke_storage_class      = module.gke.storage_class
  depends_on             = [module.gke]
}

module "argocd" {
  source                 = "./modules/argocd"
  gke_domain_name        = module.gke.cluster_domain
  depends_on             = [module.gke_env]
}

module "operator" {
  source                 = "./modules/operator"
  gke_domain_name        = module.gke.cluster_domain
  depends_on             = [module.gke_env]
}

module "rec" {
  source                 = "./modules/rec"
  domain_name            = module.gke_env.gke_domain_name
  storage_class          = module.gke_env.gke_storage_class
  tls_secret             = module.operator.tls_secret
  service_type           = var.rec_service_type
  depends_on             = [module.operator]
}

module "redb" {
  source                 = "./modules/redb"
  name                   = "redb1"
  domain_name            = module.gke_env.gke_domain_name
  cluster                = module.rec.cluster
  service_type           = module.rec.service_type
  depends_on             = [module.rec]
}

module "client" {
  source                = "./modules/client"
  name                  = "usc1-${var.name}"
  gcp_region            = module.vpc.gcp_region
  network_name          = module.vpc.vpc_name
  subnet_name           = module.vpc.subnet_name
  public_key_file       = var.public_key
  depends_on            = [module.vpc]
}
