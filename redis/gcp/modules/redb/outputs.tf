#

output "database_hostname" {
  value = local.redis_db_hostname
}

output "database_password" {
  value     = random_string.password.id
  sensitive = true
}
