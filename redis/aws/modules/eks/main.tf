#

data "aws_route53_zone" "parent" {
  zone_id = var.parent_hosted_zone_id
}

locals {
  cluster_name       = "${var.name}-eks"
  parent_domain_fqdn = trimsuffix(data.aws_route53_zone.parent.name, ".")
  cluster_domain     = "${var.name}.${local.parent_domain_fqdn}"
}

resource "aws_route53_zone" "cluster" {
  name          = "${local.cluster_domain}."
  force_destroy = true

  tags = merge(var.labels, {
    Name       = "${local.cluster_name}-dns"
    managed_by = "terraform"
  })
}

resource "aws_route53_record" "cluster_ns_delegation" {
  zone_id = var.parent_hosted_zone_id
  name    = local.cluster_domain
  type    = "NS"
  ttl     = 300
  records = aws_route53_zone.cluster.name_servers
}

resource "aws_ec2_tag" "cluster_subnet_shared" {
  count       = length(var.subnet_ids)
  resource_id = var.subnet_ids[count.index]
  key         = "kubernetes.io/cluster/${local.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "subnet_elb_role" {
  count       = length(var.subnet_ids)
  resource_id = var.subnet_ids[count.index]
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

data "aws_iam_policy_document" "eks_cluster_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${var.name}-eks-cluster"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume.json

  tags = merge(var.labels, {
    Name       = "${local.cluster_name}-cluster-role"
    managed_by = "terraform"
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

data "aws_iam_policy_document" "eks_node_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "node" {
  name               = "${var.name}-eks-node"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume.json

  tags = merge(var.labels, {
    Name       = "${local.cluster_name}-node-role"
    managed_by = "terraform"
  })
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_eks_cluster" "kubernetes" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = true
  }

  enabled_cluster_log_types = []

  tags = merge(var.labels, {
    Name       = local.cluster_name
    managed_by = "terraform"
  })

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
  ]
}

resource "aws_eks_node_group" "worker_nodes" {
  cluster_name    = aws_eks_cluster.kubernetes.name
  node_group_name = "${var.name}-node-pool"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids
  version         = var.kubernetes_version

  scaling_config {
    desired_size = var.node_count
    max_size     = var.max_node_count
    min_size     = var.min_node_count
  }

  instance_types = var.instance_types
  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"

  update_config {
    max_unavailable = 1
  }

  tags = merge(var.labels, {
    Name       = "${var.name}-node-pool"
    managed_by = "terraform"
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]

  lifecycle {
    # noinspection HILUnresolvedReference
    ignore_changes = [scaling_config[0].desired_size]
  }
}

data "tls_certificate" "eks_oidc" {
  # noinspection HILUnresolvedReference
  url = aws_eks_cluster.kubernetes.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  # noinspection HILUnresolvedReference
  url             = aws_eks_cluster.kubernetes.identity[0].oidc[0].issuer

  tags = merge(var.labels, {
    Name       = "${local.cluster_name}-oidc"
    managed_by = "terraform"
  })
}

data "aws_caller_identity" "current" {}

resource "aws_eks_access_entry" "cluster_admin" {
  cluster_name      = aws_eks_cluster.kubernetes.name
  principal_arn     = data.aws_caller_identity.current.arn
  type              = "STANDARD"
  kubernetes_groups = []

  tags = var.labels
}

resource "aws_eks_access_policy_association" "cluster_admin" {
  cluster_name  = aws_eks_cluster.kubernetes.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = data.aws_caller_identity.current.arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.cluster_admin]
}

locals {
  oidc_issuer_hostpath = replace(aws_iam_openid_connect_provider.eks.url, "https://", "")
}
