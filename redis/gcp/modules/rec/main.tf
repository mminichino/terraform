#

resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name  = "My CA"
    organization = "My Organization"
  }

  is_ca_certificate     = true
  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
  ]
}

resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "server" {
  private_key_pem = tls_private_key.server.private_key_pem

  subject {
    common_name         = "redis-enterprise-cluster"
    organization        = "RedisLabs Enterprise Cluster"
    organizational_unit = "redisdb"
  }

  dns_names = [
    "*.${var.domain_name}",
    "*.svc.cluster.local",
    "localhost"
  ]

  ip_addresses = [
    "127.0.0.1"
  ]
}

resource "tls_locally_signed_cert" "server" {
  cert_request_pem = tls_cert_request.server.cert_request_pem

  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem      = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "data_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "kubernetes_secret_v1" "proxy_cert_secret" {
  metadata {
    name      = "proxy-cert-secret"
    namespace = var.namespace
  }
  type = "Opaque"

  data = {
    certificate = base64encode(tls_locally_signed_cert.server.cert_pem)
    key         = base64encode(tls_private_key.server.private_key_pem)
    name        = "cHJveHk="
  }
}

locals {
  service_type = {
    nginx = "ClusterIP"
    lb    = "LoadBalancer"
  }

  database_service_type = {
    nginx = "cluster_ip,headless"
    lb    = "load_balancer,cluster_ip"
  }

  ingress_spec = {
    nginx = {
      ingressOrRouteSpec = {
        apiFqdnUrl   = "redis-api.${var.domain_name}"
        dbFqdnSuffix = var.domain_name
        method       = "ingress"
        ingressAnnotations = {
          "kubernetes.io/ingress.class"                 = "nginx"
          "nginx.ingress.kubernetes.io/ssl-passthrough" = "true"
        }
      }
    }
    lb    = {}
  }

  ingress_enabled = length(local.ingress_spec[var.service_type]) != 0
}

resource "kubernetes_manifest" "redis_cluster" {
  manifest = {
    apiVersion = "app.redislabs.com/v1"
    kind       = "RedisEnterpriseCluster"

    metadata = {
      name = var.name
      namespace = var.namespace
      labels = {
        app = "redis"
      }
    }

    spec = merge({
        redisEnterpriseNodeResources = {
          limits = {
            cpu = var.cpu
            memory = var.memory
          }
          requests = {
            cpu = var.cpu
            memory = var.memory
          }
        }
        nodes = var.mode_count
        persistentSpec = {
          enabled = true
          storageClassName = var.storage_class
          volumeSize = var.volume_size
        }
        username = "demo@redis.com"
        certificates = {
          proxyCertificateSecretName = "proxy-cert-secret"
        }
        uiServiceType = local.service_type[var.service_type]
        servicesRiggerSpec = {
          databaseServiceType = local.database_service_type[var.service_type]
          serviceNaming = "bdb_name"
        }
        services = {
          apiService = {
            type = local.service_type[var.service_type]
          }
        }
      },
      local.ingress_enabled ? local.ingress_spec[var.service_type] : {}
    )
  }

  wait {
    fields = {
      "status.state" = "Running"
      "status.persistenceStatus.status" = "Provisioned"
    }
  }

  depends_on = [kubernetes_secret_v1.proxy_cert_secret]
}

locals {
  redis_ui_dns_name = "redis-ui.${var.domain_name}"
  redis_ui_url_port = local.ingress_enabled ? 443 : 8443
  redis_ui_url = "https://${local.redis_ui_dns_name}:${local.redis_ui_url_port}"
}

resource "kubernetes_manifest" "cluster_ui" {
  count = local.ingress_enabled ? 1 : 0
  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name      = "${var.name}-ui"
      namespace = var.namespace
      annotations = {
        "kubernetes.io/ingress.class"                  = "nginx"
        "nginx.ingress.kubernetes.io/ssl-passthrough"  = "true"
        "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
      }
    }

    spec = {
      rules = [{
        host = local.redis_ui_dns_name
        http = {
          paths = [{
            path = "/"
            pathType = "ImplementationSpecific"
            backend = {
              service = {
                name = "${var.name}-ui"
                port = {
                  number = 8443
                }
              }
            }
          }]
        }
      }]
    }
  }

  depends_on = [kubernetes_manifest.redis_cluster]
}

data "kubernetes_service_v1" "ui_lb_service" {
  count = local.ingress_enabled ? 0 : 1
  metadata {
    name      = "${var.name}-ui"
    namespace = var.namespace
  }
  depends_on = [kubernetes_manifest.redis_cluster]
}

resource "google_dns_record_set" "ui_record" {
  count = local.ingress_enabled ? 0 : 1
  name = "${local.redis_ui_dns_name}."
  managed_zone = replace(var.domain_name, ".", "-")
  type = "A"
  ttl = 300
  # noinspection HILUnresolvedReference
  rrdatas = [data.kubernetes_service_v1.ui_lb_service.0.status.0.load_balancer.0.ingress.0.ip]
}

resource "kubernetes_manifest" "monitoring" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind = "ServiceMonitor"
    metadata = {
      name = "redis-enterprise"
      namespace = var.namespace
      labels = {
        release = "prometheus"
      }
    }
    spec = {
      endpoints = [{
        interval = "15s"
        port = "prometheus"
        scheme = "https"
        tlsConfig = {
          insecureSkipVerify = true
        }
      }]
      namespaceSelector = {
        matchNames = ["redis"]
      }
      selector = {
        matchLabels = {
          "redis.io/service" = "prom-metrics"
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.cluster_ui]
}

data "kubernetes_secret_v1" "redis_cluster_secret" {
  metadata {
    name = var.name
    namespace = var.namespace
  }
  depends_on = [kubernetes_manifest.monitoring]
}
