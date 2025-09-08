#

output "rdbms_node_private" {
  value = [aws_instance.rdbms_nodes.*.private_ip]
}

output "rdbms_node_public" {
  value = [aws_instance.rdbms_nodes.*.public_ip]
}

output "rdbms_machine_type" {
  value = var.machine_type
}
