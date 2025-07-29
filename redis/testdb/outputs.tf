# Redis Enterprise Cluster Outputs

output "redis_node_private_ips" {
  description = "Private IP addresses of Redis nodes"
  value       = module.redis-enterprise.node-private
}

output "redis_node_public_ips" {
  description = "Public IP addresses of Redis nodes"
  value       = module.redis-enterprise.node-public
}

output "redis_instance_hostnames" {
  description = "Generated hostnames for Redis instances"
  value       = module.redis-enterprise.instance_hostnames
}

output "redis_subdomain_zone_id" {
  description = "Zone ID of the created subdomain"
  value       = module.redis-enterprise.subdomain_zone_id
}

output "redis_admin_urls" {
  description = "Admin UI URLs for Redis Enterprise nodes"
  value       = [for hostname in module.redis-enterprise.instance_hostnames : "https://${hostname}:8443"]
}

output "redis_environment_info" {
  description = "Environment information"
  value = {
    environment = var.environment
    domain      = var.dns_domain
    vpc_id      = var.aws_vpc
  }
}
