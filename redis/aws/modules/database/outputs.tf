#

output "name" {
  value = var.name
}

output "port" {
  value = var.port
}

output "password" {
  value = random_string.password.id
}

output "external_endpoint" {
  value = local.external_endpoint
}

output "internal_endpoint" {
  value = local.internal_endpoint
}
