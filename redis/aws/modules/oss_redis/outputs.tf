#

output "node_private" {
  value = aws_instance.redis_nodes[*].private_ip
}

output "node_public" {
  value = aws_instance.redis_nodes[*].public_ip
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

output "cluster_endpoints" {
  value = local.cluster_endpoints
}

output "master_endpoints" {
  value = local.master_endpoints
}

output "replica_endpoints" {
  value = local.replica_endpoints
}

output "redis_machine_type" {
  value = var.redis_machine_type
}

output "node_count" {
  value = var.node_count
}

output "shards_per_node" {
  value = var.shards_per_node
}

output "instances_per_node" {
  value = local.instances_per_node
}

output "total_master_shards" {
  value = local.total_master_shards
}

output "total_replica_shards" {
  value = local.total_replica_shards
}

output "total_shards" {
  value = local.total_shards
}

output "maxmemory_bytes" {
  value = local.maxmemory_bytes
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
