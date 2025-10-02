#

output "namespace" {
  value = var.namespace
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

output "service_type" {
  value = var.service_type
}
