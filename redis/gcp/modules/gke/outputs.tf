#

output "cluster_name" {
  description = "The name of the GKE cluster."
  value       = google_container_cluster.kubernetes.name
}

output "cluster_endpoint" {
  description = "The endpoint of the GKE cluster's control plane."
  value       = google_container_cluster.kubernetes.endpoint
}

output "node_pool_name" {
  description = "The name of the GKE cluster's node pool."
  value       = google_container_node_pool.worker_nodes.name
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.kubernetes.endpoint
  description = "GKE Cluster Host"
}
