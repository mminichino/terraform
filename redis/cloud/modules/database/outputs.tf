##

output "db_id" {
  value = rediscloud_subscription_database.database.db_id
}

output "public_endpoint" {
  value = rediscloud_subscription_database.database.public_endpoint
}

output "private_endpoint" {
  value = rediscloud_subscription_database.database.private_endpoint
}

output "password" {
  value     = random_string.password.id
  sensitive = true
}
