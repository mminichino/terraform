#

locals {
  ingress_zone_name = "ingress-${replace(var.eks_domain_name, ".", "-")}"
  ingress_dns_name  = "ingress.${var.eks_domain_name}"
}

resource "aws_route53_zone" "ingress" {
  name = "${local.ingress_dns_name}."

  tags = {
    Name       = local.ingress_zone_name
    managed_by = "terraform"
  }
}

resource "aws_route53_record" "ingress_ns_delegation" {
  zone_id = var.cluster_hosted_zone_id
  name    = local.ingress_dns_name
  type    = "NS"
  ttl     = 300
  records = aws_route53_zone.ingress.name_servers
}

data "aws_iam_policy_document" "external_dns_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_issuer_hostpath}:sub"
      values   = ["system:serviceaccount:external-dns:external-dns"]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_issuer_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "external_dns" {
  statement {
    sid    = "ChangeByZone"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${var.cluster_hosted_zone_id}",
      "arn:aws:route53:::hostedzone/${aws_route53_zone.ingress.zone_id}",
    ]
  }

  statement {
    sid    = "ListZonesAndRecords"
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "external_dns" {
  name               = "${local.ingress_zone_name}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume.json
}

resource "aws_iam_role_policy" "external_dns" {
  name   = "external-dns"
  role   = aws_iam_role.external_dns.id
  policy = data.aws_iam_policy_document.external_dns.json
}

resource "helm_release" "external_dns" {
  name             = "external-dns"
  namespace        = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns"
  chart            = "external-dns"
  version          = var.external_dns_chart_version
  create_namespace = true
  cleanup_on_fail  = true

  values = [
    yamlencode({
      provider = "aws"
      aws = {
        region = var.aws_region
      }
      serviceAccount = {
        create = true
        name   = "external-dns"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns.arn
        }
      }
      txtOwnerId    = "external-dns"
      domainFilters = [var.eks_domain_name]
      policy        = "sync"
    })
  ]
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.18.2"
  create_namespace = true
  cleanup_on_fail  = true

  set = [
    {
      name  = "crds.enabled"
      value = true
    }
  ]

  depends_on = [helm_release.external_dns]
}

resource "helm_release" "haproxy_ingress" {
  name             = "haproxy-ingress"
  namespace        = "haproxy-ingress"
  repository       = "https://haproxytech.github.io/helm-charts"
  chart            = "kubernetes-ingress"
  version          = "1.46.1"
  create_namespace = true
  cleanup_on_fail  = true

  set = [
    {
      name  = "controller.replicaCount"
      value = 2
    },
    {
      name  = "controller.service.type"
      value = "LoadBalancer"
    },
    {
      name  = "controller.service.enablePorts.http"
      value = true
    },
    {
      name  = "controller.service.enablePorts.https"
      value = true
    },
    {
      name  = "controller.service.enablePorts.quic"
      value = false
    },
    {
      name  = "controller.image.repository"
      value = "docker.io/haproxytech/kubernetes-ingress"
    },
    {
      name  = "controller.image.tag"
      value = "3.1.15"
    }
  ]

  depends_on = [helm_release.cert_manager]
}

resource "random_string" "grafana_password" {
  length  = 8
  special = false
}

locals {
  grafana_hostname = "grafana.${var.eks_domain_name}"
}

resource "helm_release" "prometheus" {
  name             = "prometheus"
  namespace        = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  create_namespace = true
  cleanup_on_fail  = true

  set = [
    {
      name  = "grafana.ingress.enabled"
      value = true
    },
    {
      name  = "grafana.ingress.annotations.kubernetes\\.io/ingress\\.class"
      value = "haproxy"
    }
  ]

  set_list = [
    {
      name  = "grafana.ingress.hosts"
      value = [local.grafana_hostname]
    }
  ]

  set_sensitive = [
    {
      name  = "grafana.adminPassword"
      value = random_string.grafana_password.id
    }
  ]

  depends_on = [helm_release.haproxy_ingress]
}

data "kubernetes_service_v1" "haproxy_ingress" {
  metadata {
    name      = "haproxy-ingress-kubernetes-ingress"
    namespace = "haproxy-ingress"
  }
  depends_on = [helm_release.haproxy_ingress]
}

# noinspection HILUnresolvedReference
locals {
  lb_ingress              = try(data.kubernetes_service_v1.haproxy_ingress.status.0.load_balancer.0.ingress.0, null)
  ingress_lb_ip_raw       = local.lb_ingress != null ? local.lb_ingress.ip : null
  ingress_lb_hostname_raw = local.lb_ingress != null ? local.lb_ingress.hostname : null
  ingress_lb_ip           = local.ingress_lb_ip_raw != null && trimspace(local.ingress_lb_ip_raw) != "" ? trimspace(local.ingress_lb_ip_raw) : null
  ingress_lb_hostname     = local.ingress_lb_hostname_raw != null && trimspace(local.ingress_lb_hostname_raw) != "" ? trimspace(local.ingress_lb_hostname_raw) : null
  ingress_record_type  = local.ingress_lb_hostname != null ? "CNAME" : "A"
  ingress_record_value = local.ingress_lb_hostname != null ? local.ingress_lb_hostname : local.ingress_lb_ip
}

resource "aws_route53_record" "ingress_hostname" {
  zone_id = aws_route53_zone.ingress.zone_id
  name    = "haproxy"
  type    = local.ingress_record_type
  ttl     = 300
  records = [local.ingress_record_value]

  lifecycle {
    precondition {
      condition     = local.ingress_record_value != null
      error_message = "HAProxy LoadBalancer must expose an IP or hostname before creating the DNS record; re-run apply after the Service receives an address."
    }
  }
  depends_on = [data.kubernetes_service_v1.haproxy_ingress, helm_release.haproxy_ingress]
}

data "aws_iam_policy_document" "external_secrets_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_issuer_hostpath}:sub"
      values   = ["system:serviceaccount:external-secrets:external-secrets"]
    }
    condition {
      test     = "StringEquals"
      variable = "${var.oidc_issuer_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "external_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "external_secrets" {
  name               = "${local.ingress_zone_name}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume.json
}

resource "aws_iam_role_policy" "external_secrets" {
  name   = "external-secrets"
  role   = aws_iam_role.external_secrets.id
  policy = data.aws_iam_policy_document.external_secrets.json
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  namespace        = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "1.2.1"
  create_namespace = true
  cleanup_on_fail  = true

  set = [
    {
      name  = "serviceAccount.create"
      value = true
    },
    {
      name  = "serviceAccount.name"
      value = "external-secrets"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.external_secrets.arn
    }
  ]

  depends_on = [aws_route53_record.ingress_hostname]
}

resource "helm_release" "aws_secret_store" {
  name            = "aws-secret-store"
  namespace       = "external-secrets"
  repository      = "https://mminichino.github.io/helm-charts"
  chart           = "aws-secret-store"
  version         = "0.1.1"
  cleanup_on_fail = true

  set = [
    {
      name  = "region"
      value = var.aws_region
    }
  ]

  depends_on = [helm_release.external_secrets]
}
