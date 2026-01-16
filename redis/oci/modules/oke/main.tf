#

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

locals {
  k8s_version = var.kubernetes_version
  ad_name = data.oci_identity_availability_domains.ads.availability_domains[0].name
  k8s_no_v = replace(local.k8s_version, "v", "")
  oke_x86_image_ids = [
    for s in data.oci_containerengine_node_pool_option.np_opts.sources : s.image_id
    if (
    can(regex("OKE-${local.k8s_no_v}", s.source_name))
    && can(regex("Oracle-Linux", s.source_name))
    && !can(regex("aarch64|A1|Ampere", s.source_name))
    && !can(regex("GPU", s.source_name))
    )
  ]
  node_image_id = local.oke_x86_image_ids[0]
}

data "oci_containerengine_node_pool_option" "np_opts" {
  node_pool_option_id  = "all"
  compartment_id       = var.compartment_ocid
  node_pool_k8s_version = local.k8s_version
}

resource "oci_containerengine_cluster" "oke" {
  compartment_id     = var.compartment_ocid
  name               = "${var.name}-oke-cluster"
  kubernetes_version = local.k8s_version
  vcn_id             = var.vcn_id
  type               = "ENHANCED_CLUSTER"

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = var.api_subnet_id
  }

  cluster_pod_network_options {
    cni_type = "OCI_VCN_IP_NATIVE"
  }

  options {
    service_lb_subnet_ids = [var.lb_subnet_id]
  }
}

resource "oci_containerengine_node_pool" "workers" {
  compartment_id     = var.compartment_ocid
  cluster_id         = oci_containerengine_cluster.oke.id
  name               = "${var.name}-node-pool"
  kubernetes_version = local.k8s_version

  node_shape = "VM.Standard.E4.Flex"

  node_shape_config {
    ocpus         = 4
    memory_in_gbs = 32
  }

  node_source_details {
    source_type            = "IMAGE"
    image_id               = local.node_image_id
    boot_volume_size_in_gbs = 128
  }

  node_config_details {
    size = 3

    placement_configs {
      availability_domain = local.ad_name
      subnet_id           = var.node_subnet_id
    }

    node_pool_pod_network_option_details {
      cni_type       = "OCI_VCN_IP_NATIVE"
      pod_subnet_ids = [var.pod_subnet_id]
    }
  }

  ssh_public_key = file("~/.ssh/${var.ssh_public_key}")
}

data "oci_containerengine_cluster_kube_config" "cluster_kube_config" {
  cluster_id    = oci_containerengine_cluster.oke.id
  token_version = "2.0.0"
}

# noinspection HILUnresolvedReference
locals {
  kubeconfig             = yamldecode(data.oci_containerengine_cluster_kube_config.cluster_kube_config.content)
  kube_cluster           = local.kubeconfig.clusters[0].cluster
  kube_user_exec         = local.kubeconfig.users[0].user.exec
  api_host               = local.kube_cluster.server
  cluster_ca_certificate = base64decode(local.kube_cluster["certificate-authority-data"])
  exec_api_version       = local.kube_user_exec.apiVersion
  exec_command           = local.kube_user_exec.command
  exec_args              = local.kube_user_exec.args
}
