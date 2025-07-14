output "node-private" {
  value = [aws_instance.ubuntu.*.private_ip]
}

output "node-public" {
  value = [aws_instance.ubuntu.*.public_ip]
}
