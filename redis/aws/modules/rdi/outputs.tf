#

output "rdi_private" {
  value = [aws_instance.rdi_nodes.*.private_ip]
}

output "rdi_public" {
  value = [aws_instance.rdi_nodes.*.public_ip]
}

output "rdi_machine_type" {
  description = "Client node AWS instance type"
  value = var.rdi_machine_type
}
