#

output "cluster" {
  value = {
    kubeconfig = data.oci_containerengine_cluster_kube_config.cluster_kube_config.content
    ocid = oci_containerengine_cluster.oke.id
  }
}

output "api_host" {
  value = local.api_host
}

output "cluster_ca_data" {
  value = local.cluster_ca_data
}

output "cluster_ca_certificate" {
  value = local.cluster_ca_certificate
}

output "exec_api_version" {
  value = local.exec_api_version
}

output "exec_command" {
  value = local.exec_command
}

output "exec_args" {
  value = local.exec_args
}
