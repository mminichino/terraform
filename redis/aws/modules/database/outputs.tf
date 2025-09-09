#

output "name" {
  value = var.name
}

output "port" {
  value = var.port
}

output "redis_password" {
  value = random_string.password.id
}
