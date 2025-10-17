##

output "public_endpoint" {
  value = rediscloud_essentials_database.database.public_endpoint
}

output "private_endpoint" {
  value = rediscloud_essentials_database.database.private_endpoint
}
