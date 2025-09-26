#

output "database_hostname" {
  value = local.redis_db_hostname
}

output "database_port" {
  value = var.port
}

output "database_password" {
  value     = random_string.password.id
  sensitive = true
}
