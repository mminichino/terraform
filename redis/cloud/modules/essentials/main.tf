##

data "rediscloud_payment_method" "card" {}

data "rediscloud_essentials_plan" "plan" {
  name           = var.plan
  cloud_provider = var.cloud
  region         = var.region
}

resource "random_string" "password" {
  length  = 8
  special = false
}

resource "rediscloud_essentials_subscription" "subscription" {
  name              = "${var.name}-sub"
  plan_id           = data.rediscloud_essentials_plan.plan.id
  payment_method_id = data.rediscloud_payment_method.card.id
}

resource "rediscloud_essentials_database" "database" {
  subscription_id     = rediscloud_essentials_subscription.subscription.id
  name                = var.name
  enable_default_user = true
  password            = random_string.password.id

  data_persistence = var.persistence
  data_eviction    = var.eviction
  replication      = var.replication
}
