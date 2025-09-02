#

output "aws_ssh_key_name" {
  value = aws_key_pair.key_pair.key_name
}
