# Redis Enterprise Cluster

module "redis-enterprise" {
  source = "./modules/redis"
  environment_name = ""
  ssh_key          = ""
  ssh_private_key  = ""
  vpc_id           = ""
}
