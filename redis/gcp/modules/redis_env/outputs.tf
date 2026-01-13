#

output "cluster_password" {
  value     = data.kubernetes_secret_v1.redis_cluster_secret.data["password"]
  sensitive = true
}

output "cluster_url" {
  value = local.redis_ui_url
}

output "redb_password" {
  value     = random_string.redb_password.id
  sensitive = true
}

output "rdidb_password" {
  value     = random_string.rdidb_password.id
  sensitive = true
}
