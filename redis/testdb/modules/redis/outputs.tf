output "node-private" {
  value = [aws_instance.redis_nodes.*.private_ip]
}

output "node-public" {
  value = [aws_instance.redis_nodes.*.public_ip]
}

output "instance_hostnames" {
  description = "Generated hostnames for instances"
  value       = [for i in range(var.node_count) : "host${i + 1}.${var.environment_name}.${var.parent_domain}"]
}

output "subdomain_zone_id" {
  description = "Zone ID of the created subdomain"
  value       = aws_route53_zone.subdomain.zone_id
}

output "subdomain_name_servers" {
  description = "Name servers for the subdomain"
  value       = aws_route53_zone.subdomain.name_servers
}

output "vpc_dns_address" {
  description = "VPC DNS server"
  value       = local.vpc_dns_server
}
