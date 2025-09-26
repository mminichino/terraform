#

output "namespace" {
  value = var.namespace
}

output "server_certificate_pem" {
  value = tls_locally_signed_cert.server.cert_pem
}

output "server_private_key_pem" {
  value     = tls_private_key.server.private_key_pem
  sensitive = true
}

output "ca_certificate_pem" {
  value = tls_self_signed_cert.ca.cert_pem
}

output "cluster" {
  value = var.name
}

output "cluster_password" {
  value     = data.kubernetes_secret_v1.redis_cluster_secret.data["password"]
  sensitive = true
}

output "ingress_enabled" {
  value = local.ingress_enabled
}

output "redis_ui_url" {
  value = local.redis_ui_url
}
