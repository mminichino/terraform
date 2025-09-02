#

output "node_private" {
  value = [aws_instance.redis_nodes.*.private_ip]
}

output "node_public" {
  value = [aws_instance.redis_nodes.*.public_ip]
}

output "instance_hostnames" {
  description = "Generated hostnames for instances"
  value       = [for i in range(var.node_count) : "node${i + 1}.${var.environment_id}.${var.parent_domain}"]
}

output "redis_machine_type" {
  description = "Redis node AWS instance type"
  value = var.redis_machine_type
}
