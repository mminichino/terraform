output "vcn_id" {
  value = module.vcn.vcn_id
}

output "public_subnet_id" {
  value = module.vcn.public_subnet_id
}

output "private_subnet_id" {
  value = module.vcn.private_subnet_id
}

output "kubeconfig" {
  value = module.oke.cluster.kubeconfig
}
