#

output "node_private" {
  value = aws_instance.mongo_nodes[*].private_ip
}

output "node_public" {
  value = aws_instance.mongo_nodes[*].public_ip
}

output "instance_hostnames" {
  value = local.instance_hostnames
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

output "member_endpoints" {
  value = local.member_endpoints
}

output "connection_string" {
  value     = "mongodb://admin:${random_password.password.result}@${join(",", local.member_endpoints)}/?replicaSet=${var.repl_set_name}&authSource=admin"
  sensitive = true
}

output "repl_set_name" {
  value = var.repl_set_name
}

output "mongo_machine_type" {
  value = var.mongo_machine_type
}

output "node_count" {
  value = var.node_count
}

output "mongodb_version" {
  value = var.mongodb_version
}

output "admin_user" {
  value = "admin"
}

output "password" {
  value     = random_password.password.result
  sensitive = true
}

output "cpu_count" {
  value = local.cpu_count
}

output "memory_mib" {
  value = local.memory_mib
}
