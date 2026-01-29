##

data "rediscloud_payment_method" "card" {}

data "rediscloud_cloud_account" "account" {
  exclude_internal_account = true
  provider_type            = var.cloud
  name                     = var.account_name
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
    dataset_size_in_gb           = var.max_db_size
    quantity                     = var.db_quantity
    replication                  = var.replication
    throughput_measurement_by    = var.throughput_measurement
    throughput_measurement_value = var.throughput
  }
}
