#

output "cluster_name" {
  description = "The name of the GKE cluster."
  value       = google_container_cluster.kubernetes.name
}

output "cluster_domain" {
  value = local.cluster_domain
}

output "cluster_endpoint" {
  description = "The endpoint of the GKE cluster's control plane."
  value       = google_container_cluster.kubernetes.endpoint
}

output "cluster_endpoint_url" {
  value = "https://${google_container_cluster.kubernetes.endpoint}"
}

output "cluster_sa_email" {
  value = data.google_client_openid_userinfo.current.email
}

output "node_pool_name" {
  description = "The name of the GKE cluster's node pool."
  value       = google_container_node_pool.worker_nodes.name
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.kubernetes.endpoint
  description = "GKE Cluster Host"
}

output "access_token" {
  value = data.google_client_config.provider.access_token
}

output "cluster_ca_certificate" {
  value = base64decode(google_container_cluster.kubernetes.master_auth[0].cluster_ca_certificate)
}

output "storage_class" {
  value = var.storage_class_name
}
