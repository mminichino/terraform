# Redis Enterprise Cluster Outputs

output "redis_node_private_ips" {
  description = "Private IP addresses of Redis nodes"
  value       = module.redis.node_private
}

output "redis_node_public_ips" {
  description = "Public IP addresses of Redis nodes"
  value       = module.redis.node_public
}

output "redis_instance_hostnames" {
  description = "Generated hostnames for Redis instances"
  value       = module.redis.instance_hostnames
}

output "redis_admin_urls" {
  description = "Admin UI URLs for Redis Enterprise nodes"
  value       = [for hostname in module.redis.instance_hostnames : "https://${hostname}:8443"]
}

output "environment_info" {
  description = "Environment information"
  value = {
    environment = var.name
    domain      = var.gcp_domain
    vpc_id      = module.vpc.vpc_name
    user        = module.redis.admin_user
    password    = module.redis.password
  }
}
