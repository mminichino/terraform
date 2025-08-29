output "node_private" {
  value = [aws_instance.redis_nodes.*.private_ip]
}

output "node_public" {
  value = [aws_instance.redis_nodes.*.public_ip]
}

output "client_private" {
  value = [aws_instance.client_nodes.*.private_ip]
}

output "client_public" {
  value = [aws_instance.client_nodes.*.public_ip]
}

output "instance_hostnames" {
  description = "Generated hostnames for instances"
  value       = [for i in range(var.node_count) : "node${i + 1}.${random_string.env_key.id}.${var.parent_domain}"]
}

output "vpc_dns_address" {
  description = "VPC DNS server"
  value       = local.vpc_dns_server
}

output "aws_vpc_id" {
  description = "VPC id"
  value = aws_vpc.vpc.id
}

output "redis_machine_type" {
  description = "Redis node AWS instance type"
  value = var.redis_machine_type
}

output "client_machine_type" {
  description = "Client node AWS instance type"
  value = var.client_machine_type
}
