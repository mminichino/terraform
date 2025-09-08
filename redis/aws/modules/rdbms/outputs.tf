#

output "node_private" {
  value = [aws_instance.rdbms_nodes.*.private_ip]
}

output "node_public" {
  value = [aws_instance.rdbms_nodes.*.public_ip]
}

output "redis_machine_type" {
  value = var.machine_type
}
