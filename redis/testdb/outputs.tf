# Redis Enterprise Cluster Outputs

output "redis_node_private_ips" {
  description = "Private IP addresses of Redis nodes"
  value       = module.redis-enterprise.node_private
}

output "redis_node_public_ips" {
  description = "Public IP addresses of Redis nodes"
  value       = module.redis-enterprise.node_public
}

output "client_node_private_ips" {
  description = "Private IP addresses of Client nodes"
  value       = module.redis-enterprise.client_private
}

output "client_node_public_ips" {
  description = "Public IP addresses of Client nodes"
  value       = module.redis-enterprise.client_public
}

output "redis_instance_hostnames" {
  description = "Generated hostnames for Redis instances"
  value       = module.redis-enterprise.instance_hostnames
}

output "redis_admin_urls" {
  description = "Admin UI URLs for Redis Enterprise nodes"
  value       = [for hostname in module.redis-enterprise.instance_hostnames : "https://${hostname}:8443"]
}

output "environment_info" {
  description = "Environment information"
  value = {
    environment = var.environment
    domain      = var.dns_domain
    vpc_id      = module.redis-enterprise.aws_vpc_id
    vpc_dns     = module.redis-enterprise.vpc_dns_address
    client      = module.redis-enterprise.client_machine_type
    node        = module.redis-enterprise.redis_machine_type
  }
}
