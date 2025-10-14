##

provider "rediscloud" {
  api_key    = var.api_key
  secret_key = var.secret_key
}

module "cloud_db" {
  source = "./modules/database"
  name   = var.name
  cloud  = var.cloud
  region = var.region
}
