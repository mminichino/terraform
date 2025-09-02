#

output "client_private" {
  value = [aws_instance.client_nodes.*.private_ip]
}

output "client_public" {
  value = [aws_instance.client_nodes.*.public_ip]
}

output "client_machine_type" {
  description = "Client node AWS instance type"
  value = var.client_machine_type
}
