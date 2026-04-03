#

module "cluster" {
  source                      = "../eks_cluster"
  name                        = var.name
  eks_cluster_name            = var.eks_cluster_name
  aws_region                  = var.aws_region
  cluster_admin_principal_arn = var.cluster_admin_principal_arn
  parent_hosted_zone_id       = var.parent_hosted_zone_id
  parent_domain_fqdn          = var.parent_domain_fqdn
  subnet_ids                  = var.subnet_ids
  kubernetes_version          = var.kubernetes_version
  node_release_version        = var.node_release_version
  node_count                  = var.node_count
  max_node_count              = var.max_node_count
  min_node_count              = var.min_node_count
  instance_types              = var.instance_types
  install_aws_ebs_csi_driver  = var.install_aws_ebs_csi_driver
  endpoint_public_access      = var.endpoint_public_access
  tags                        = var.tags
}

provider "kubernetes" {
  host                   = module.cluster.cluster_endpoint_url
  cluster_ca_certificate = module.cluster.cluster_ca_certificate

  exec {
    api_version = module.cluster.exec_api_version
    command     = module.cluster.exec_command
    args        = module.cluster.exec_args
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.cluster.cluster_endpoint_url
    cluster_ca_certificate = module.cluster.cluster_ca_certificate

    exec = {
      api_version = module.cluster.exec_api_version
      command     = module.cluster.exec_command
      args        = module.cluster.exec_args
    }
  }
}

module "eks_env" {
  source                     = "../eks_env"
  eks_domain_name            = module.cluster.cluster_domain
  cluster_hosted_zone_id     = module.cluster.cluster_hosted_zone_id
  aws_region                 = var.aws_region
  oidc_provider_arn          = module.cluster.oidc_provider_arn
  oidc_issuer_hostpath       = module.cluster.oidc_issuer_hostpath
  external_dns_chart_version = var.external_dns_chart_version
  depends_on                 = [module.cluster]
}
