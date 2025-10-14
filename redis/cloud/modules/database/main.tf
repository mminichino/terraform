##

data "rediscloud_payment_method" "card" {}

data "rediscloud_cloud_account" "account" {
  exclude_internal_account = true
  provider_type            = var.cloud
}

resource "random_string" "password" {
  length  = 8
  special = false
}

resource "rediscloud_subscription" "subscription" {

  name              = "${var.name}-sub"
  payment_method    = "credit-card"
  payment_method_id = data.rediscloud_payment_method.card.id

  cloud_provider {
    provider = data.rediscloud_cloud_account.account.provider_type
    region {
      region                     = var.region
      networking_deployment_cidr = var.cidr
    }
  }

  creation_plan {
    dataset_size_in_gb           = var.memory_gb
    quantity                     = 1
    replication                  = var.replication
    throughput_measurement_by    = var.throughput_measurement
    throughput_measurement_value = var.throughput
  }
}

resource "rediscloud_subscription_database" "database" {
  subscription_id              = rediscloud_subscription.subscription.id
  name                         = var.name
  dataset_size_in_gb           = var.memory_gb
  data_persistence             = var.persistence
  throughput_measurement_by    = var.throughput_measurement
  throughput_measurement_value = var.throughput
  replication                  = var.replication
  password                     = random_string.password.id
  tags                         = var.tags

  modules = [
      for name in var.modules : {
      name = name
    }
  ]
}
