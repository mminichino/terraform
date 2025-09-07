#

output "node_private" {
  value = [aws_instance.redis_nodes.*.private_ip]
}

output "node_public" {
  value = [aws_instance.redis_nodes.*.public_ip]
}

output "instance_hostnames" {
  value       = [for i in range(var.node_count) : "node${i + 1}.${var.name}.${var.parent_domain}"]
}

output "admin_urls" {
  value       = [for i in range(var.node_count) : "https://node${i + 1}.${var.name}.${var.parent_domain}:8443"]
}

output "redis_machine_type" {
  value = var.redis_machine_type
}

output "admin_user" {
  value = var.admin_user
}

output "password" {
  value = random_string.password.id
}
