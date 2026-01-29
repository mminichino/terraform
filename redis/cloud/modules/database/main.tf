##

resource "random_string" "password" {
  length  = 8
  special = false
}

resource "rediscloud_subscription_database" "database" {
  subscription_id              = var.subscription_id
  name                         = var.name
  dataset_size_in_gb           = var.memory_gb
  data_persistence             = var.persistence
  throughput_measurement_by    = var.throughput_measurement
  throughput_measurement_value = var.throughput
  replication                  = var.replication
  password                     = random_string.password.id
  tags                         = var.tags
}
