#

resource "helm_release" "rdi_sys_config" {
  name             = "rdi-sys-config"
  namespace        = "rdi"
  repository       = "https://mminichino.github.io/helm-charts"
  chart            = "rdi-sys-config"
  version          = var.rdi_sys_config_version
  create_namespace = true
  cleanup_on_fail  = true

  set = [
    {
      name  = "connection.username"
      value = var.connection_username
    },
    {
      name  = "externalSecret.enabled"
      value = var.external_secrets_enabled
    },
    {
      name  = "externalSecret.store.name"
      value = var.external_secret_store
    },
    {
      name  = "externalSecret.password"
      value = var.rdidb_password_key
    },
    {
      name  = "externalSecret.token"
      value = var.rdi_token_key
    },
  ]
}

resource "helm_release" "rdi_db_secrets" {
  name             = "rdi-db-secrets"
  namespace        = "rdi"
  repository       = "https://mminichino.github.io/helm-charts"
  chart            = "rdi-db-secrets"
  version          = var.rdi_db_secrets_version
  cleanup_on_fail  = true

  set = [
    {
      name  = "connection.sourceUsername"
      value = var.source_username
    },
    {
      name  = "connection.targetUsername"
      value = var.target_username
    },
    {
      name  = "externalSecret.enabled"
      value = var.external_secrets_enabled
    },
    {
      name  = "externalSecret.store.name"
      value = var.external_secret_store
    },
    {
      name  = "externalSecret.source"
      value = var.source_key
    },
    {
      name  = "externalSecret.target"
      value = var.target_key
    }
  ]
}

resource "helm_release" "redis_di_cli" {
  name             = "redis-di-cli"
  namespace        = "rdi"
  repository       = "https://mminichino.github.io/helm-charts"
  chart            = "redis-di-cli"
  version          = var.rdi_di_cli_version
  cleanup_on_fail  = true
}

resource "helm_release" "rdi" {
  name             = "rdi"
  namespace        = "rdi"
  repository       = "https://mminichino.github.io/helm-charts"
  chart            = "rdi"
  version          = var.rdi_version
  cleanup_on_fail  = true

  values = [
    yamlencode({
      global = {
        logLevel = "INFO"
        image = {
          registry   = "docker.io"
          repository = "redis"
          tag        = "1.15.0"
        }
        securityContext = {
          runAsNonRoot             = true
          runAsUser                = 1000
          runAsGroup               = 1000
          allowPrivilegeEscalation = false
        }
        createSecrets = false
      }

      connection = {
        host     = "${var.rdidb}.${var.rdidb_namespace}.svc.cluster.local"
        port     = var.rdidb_port
        username = ""
        password = ""
        ssl = {
          enabled = false
        }
      }

      reloader = {
        reloader = {
          watchGlobally = false
          isOpenshift   = false
          deployment = {
            containerSecurityContext = {
              allowPrivilegeEscalation = false
              capabilities = {
                drop = ["ALL"]
              }
            }
            securityContext = {
              runAsUser = null
            }
          }
        }
        fullnameOverride = "rdi-reloader"
      }

      operator = {
        image = {
          name       = "rdi-operator"
          pullPolicy = "IfNotPresent"
        }
        liveness = {
          failureThreshold = 3
          periodSeconds    = 20
        }
        readiness = {
          failureThreshold = 3
          periodSeconds    = 10
        }
        startup = {
          failureThreshold = 24
          periodSeconds    = 5
        }
        dataPlane = {
          collector = {
            image = {
              registry   = "docker.io"
              repository = "redislabs/debezium-server"
              tag        = "3.0.8.Final-rdi.1"
            }
            serviceMonitor = {
              enabled = true
              labels = {
                release = "prometheus"
              }
            }
          }
          flinkCollector = {
            serviceMonitor = {
              enabled = true
              labels = {
                release = "prometheus"
              }
            }
          }
        }
      }

      fluentd = {
        image = {
          name       = "rdi-fluentd"
          pullPolicy = "IfNotPresent"
        }
        rdiLogsHostPath  = "/opt/rdi/logs"
        podLogsHostPath  = "/var/log/pods"
        logrotateMinutes = "5"
      }

      rdiMetricsExporter = {
        image = {
          name       = "rdi-monitor"
          pullPolicy = "IfNotPresent"
        }
        service = {
          type = "ClusterIP"
          port = 9121
        }
        liveness = {
          failureThreshold = 6
          periodSeconds    = 10
        }
        readiness = {
          failureThreshold = 6
          periodSeconds    = 30
        }
        startup = {
          failureThreshold = 60
          periodSeconds    = 5
        }
        serviceMonitor = {
          enabled = true
          labels = {
            release = "prometheus"
          }
        }
        ingress = {
          enabled    = false
          pathPrefix = ""
        }
      }

      api = {
        image = {
          name       = "rdi-api"
          pullPolicy = "IfNotPresent"
        }
        jwtKey = "replace_on_install" # You should probably use a Terraform variable here
        service = {
          type       = "ClusterIP"
          port       = 8080
          targetPort = 8081
        }
        liveness = {
          failureThreshold = 6
          periodSeconds    = 10
        }
        readiness = {
          failureThreshold = 6
          periodSeconds    = 30
        }
        startup = {
          failureThreshold = 60
          periodSeconds    = 5
        }
      }

      ingress = {
        enabled = true
        hosts   = ["rdiapi.${var.domain_name}"]
        annotations = {
          "kubernetes.io/ingress.class" = "haproxy"
        }
        pathPrefix = ""
        tls = {
          enabled = false
        }
      }
    })
  ]
}
