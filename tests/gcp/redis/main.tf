#

provider "google" {
  credentials = file(var.credential_file)
  project     = var.project
  region      = var.region
}

module "vpc" {
  source                = "../../../redis/gcp/modules/vpc"
  name                  = "usc1-${var.name}"
  cidr_block            = "10.88.0.0/16"
  gcp_project_id        = var.project
  gcp_region            = var.region
}

module "redis" {
  source                = "../../../redis/gcp/modules/redis"
  gcp_region            = var.region
  gcp_zone_name         = var.gcp_domain
  name                  = "usc1-${var.name}"
  network_name          = module.vpc.vpc_name
  private_key_file      = var.private_key
  public_key_file       = var.public_key
  redis_distribution    = var.installer_tar
  subnet_name           = module.vpc.subnet_name
  depends_on            = [module.vpc]
}
