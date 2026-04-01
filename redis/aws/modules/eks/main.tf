#

data "aws_route53_zone" "parent" {
  zone_id = var.parent_hosted_zone_id
}

locals {
  cluster_name = coalesce(var.eks_cluster_name, "${var.name}-eks")
  parent_domain_fqdn = coalesce(
    var.parent_domain_fqdn,
    trimsuffix(data.aws_route53_zone.parent.name, "."),
  )
  cluster_domain = "${var.name}.${local.parent_domain_fqdn}"
}

resource "aws_route53_zone" "cluster" {
  name          = "${local.cluster_domain}."
  force_destroy = true

  tags = merge(var.tags, {
    Name       = "${local.cluster_name}-dns"
    managed_by = "terraform"
  })

  lifecycle {
    precondition {
      condition     = var.parent_domain_fqdn == null || trimsuffix(data.aws_route53_zone.parent.name, ".") == var.parent_domain_fqdn
      error_message = "parent_domain_fqdn must exactly match the domain name of the Route 53 zone identified by parent_hosted_zone_id."
    }
  }
}

resource "aws_route53_record" "cluster_ns_delegation" {
  zone_id = var.parent_hosted_zone_id
  name    = local.cluster_domain
  type    = "NS"
  ttl     = 300
  records = aws_route53_zone.cluster.name_servers
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

  tags = merge(var.tags, {
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

  tags = merge(var.tags, {
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

  access_config {
    authentication_mode = "API"
  }

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = true
  }

  enabled_cluster_log_types = []

  tags = merge(var.tags, {
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

  tags = merge(var.tags, {
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
  url = aws_eks_cluster.kubernetes.identity[0].oidc[0].issuer

  tags = merge(var.tags, {
    Name       = "${local.cluster_name}-oidc"
    managed_by = "terraform"
  })
}

data "aws_iam_policy_document" "ebs_csi_assume" {
  count = var.install_aws_ebs_csi_driver ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  count = var.install_aws_ebs_csi_driver ? 1 : 0

  name               = "${var.name}-eks-aws-ebs-csi"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume[0].json

  tags = merge(var.tags, {
    Name       = "${local.cluster_name}-ebs-csi"
    managed_by = "terraform"
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  count = var.install_aws_ebs_csi_driver ? 1 : 0

  role       = aws_iam_role.ebs_csi[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "aws_ebs_csi_driver" {
  count = var.install_aws_ebs_csi_driver ? 1 : 0

  cluster_name                = aws_eks_cluster.kubernetes.name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = aws_iam_role.ebs_csi[0].arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi_driver,
    aws_eks_node_group.worker_nodes,
  ]

  tags = var.tags
}

resource "aws_eks_access_entry" "cluster_admin" {
  cluster_name      = aws_eks_cluster.kubernetes.name
  principal_arn     = var.cluster_admin_principal_arn
  type              = "STANDARD"
  kubernetes_groups = []

  tags = var.tags
}

resource "aws_eks_access_policy_association" "cluster_admin" {
  cluster_name  = aws_eks_cluster.kubernetes.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.cluster_admin_principal_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.cluster_admin]
}

locals {
  oidc_issuer_hostpath = replace(aws_iam_openid_connect_provider.eks.url, "https://", "")
}
