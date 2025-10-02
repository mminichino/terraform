#

output "namespace" {
  value = var.namespace
}

output "operator_version" {
  value = var.operator_version
}

output "tls_secret" {
  value = var.tls_secret
}

output "keystore_secret" {
  value     = random_string.password.id
  sensitive = true
}
