##

provider "rediscloud" {
  api_key    = var.api_key
  secret_key = var.secret_key
}

module "subscription" {
  source = "./modules/subscription"
  name   = var.name
  cloud  = var.cloud
  region = var.region
}

module "database" {
  source          = "./modules/database"
  name            = var.name
  subscription_id = module.subscription.subscription_id
}
