#

output "cluster_password" {
  value     = data.kubernetes_secret_v1.redis_cluster_secret.data["password"]
  sensitive = true
}

output "cluster_url" {
  value = "https://${local.cluster_ip}:8443"
}

output "redb_password" {
  value     = random_string.redb_password.id
  sensitive = true
}

output "rdidb_password" {
  value     = random_string.rdidb_password.id
  sensitive = true
}

output "redb_lb_ip" {
  value = local.redb_lb_ip
}

output "rdidb_lb_ip" {
  value = local.rdidb_lb_ip
}
