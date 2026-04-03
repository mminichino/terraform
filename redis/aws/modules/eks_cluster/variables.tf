#

variable "name" {
  description = "Name prefix for the EKS cluster and related resources. Also forms the leftmost DNS label (cluster_domain = \"<name>.<parent>\"). Changing this after create replaces the cluster Route53 zone and tears down dependent eks_env resources."
  type        = string
  default     = "eks-cluster"
}

variable "eks_cluster_name" {
  description = "Kubernetes cluster name (aws_eks_cluster.name). When null (default), uses the module name input plus the suffix \"-eks\". Override when the cluster name must differ; pass the same value to redis/aws/modules/vpc eks_cluster_name so subnet tags stay aligned."
  type        = string
  default     = null
}

variable "aws_region" {
  description = "AWS region for the EKS cluster."
  type        = string
}

variable "cluster_admin_principal_arn" {
  description = "IAM principal ARN for EKS API access (AmazonEKSClusterAdminPolicy). Must be resolved in the root module (e.g. data.aws_caller_identity.current.arn), not via a data source inside this module, when module.eks uses depends_on = [module.vpc]; otherwise Terraform can defer the read until apply and replace aws_eks_access_entry every run (provider ForceNew on principal_arn)."
  type        = string
}

variable "parent_hosted_zone_id" {
  description = "Route53 hosted zone ID for the parent domain (delegates a subdomain for this cluster, matching the GKE DNS pattern). Changing this replaces the cluster hosted zone if the new zone has a different domain name."
  type        = string
}

variable "parent_domain_fqdn" {
  description = "Optional. Parent DNS name without trailing dot (e.g. demo.example.com), must match parent_hosted_zone_id. When set, cluster_domain uses this instead of reading the zone name from the data source, so upgrades and provider behavior cannot drift the computed FQDN."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS control plane and worker nodes. With redis/aws/modules/vpc and the same module name, subnet tags default to the same cluster name as this module (coalesce(eks_cluster_name, \"<name>-eks\"))."
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster and managed node group."
  type        = string
  default     = "1.34"
}

variable "node_release_version" {
  description = "Kubernetes version for the cluster and managed node group."
  type        = string
  default     = "1.34.4-20260318"
}

variable "node_count" {
  description = "Desired capacity for the managed node group."
  type        = number
  default     = 3
}

variable "max_node_count" {
  description = "Maximum size for the managed node group."
  type        = number
  default     = null
}

variable "min_node_count" {
  description = "Minimum size for the managed node group."
  type        = number
  default     = null
}

variable "instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["m5.xlarge"]
}

variable "install_aws_ebs_csi_driver" {
  description = "Install the amazonaws.com EKS add-on aws-ebs-csi-driver with IRSA so StorageClasses using ebs.csi.aws.com (default gp2) can provision volumes on managed node groups."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Whether the Kubernetes API server endpoint is publicly reachable."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to taggable resources."
  type        = map(string)
  default     = {}
}
