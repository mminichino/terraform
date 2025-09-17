#

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
