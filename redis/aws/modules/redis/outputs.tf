#

output "node_private" {
  value = [aws_instance.redis_nodes.*.private_ip]
}

output "node_public" {
  value = [aws_instance.redis_nodes.*.public_ip]
}

output "instance_hostnames" {
  value = local.instance_hostnames
}

output "admin_urls" {
  value = local.admin_urls
}

output "cluster_domain" {
  value = local.cluster_domain
}

output "primary_node_public_ip" {
  value = local.primary_node_public_ip
}

output "primary_node_private_ip" {
  value = local.primary_node_private_ip
}

output "api_public_base_url" {
  value = local.api_public_base_url
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
