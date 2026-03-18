#

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

output "insight_password" {
  value     = random_string.redis_insight_password.id
  sensitive = true
}
