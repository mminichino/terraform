#

output "environment_name" {
  value = var.environment_name
}

output "environment_id" {
  value = random_string.env_key.id
}

output "name_prefix" {
  value = local.name_prefix
}

output "aws_ssh_key_name" {
  value = aws_key_pair.key_pair.key_name
}

output "aws_region" {
  value = var.aws_region
}

output "password" {
  value = random_string.password.id
}
