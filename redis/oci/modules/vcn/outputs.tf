output "vcn_id" {
  value = oci_core_vcn.this.id
}

output "public_subnet_id" {
  value = oci_core_subnet.public.id
}

output "private_subnet_id" {
  value = oci_core_subnet.private.id
}

output "api_subnet_id" {
  value = oci_core_subnet.api_endpoint_subnet.id
}

output "lb_subnet_id" {
  value = oci_core_subnet.lb_subnet.id
}

output "node_subnet_id" {
  value = oci_core_subnet.nodes_subnet.id
}

output "pod_subnet_id" {
  value = oci_core_subnet.pods_subnet.id
}
