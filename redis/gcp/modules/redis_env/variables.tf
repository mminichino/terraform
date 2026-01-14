#

variable "operator_version" {
  type    = string
  default = "8.0.6-8"
}

variable "cluster_chart_version" {
  type    = string
  default = "0.3.0"
}

variable "database_chart_version" {
  type    = string
  default = "0.2.0"
}

variable "domain_name" {
  type    = string
  default = ""
}

variable "tls_secret" {
  type    = string
  default = ""
}

variable "namespace" {
  type    = string
  default = "redis"
}

variable "cpu" {
  type    = string
  default = "4"
}

variable "memory" {
  type    = string
  default = "8Gi"
}

variable "mode_count" {
  type    = number
  default = 3
}

variable "storage_class" {
  type    = string
  default = "premium-rwo"
}

variable "volume_size" {
  type    = string
  default = "80Gi"
}

variable "license" {
  type    = string
  default = ""
}

variable "external_secret_enabled" {
  type    = bool
  default = true
}

variable "external_secret_store" {
  type    = string
  default = "gcsm-store"
}

variable "external_secret_cluster_key" {
  type    = string
  default = ""
}

variable "external_secret_redb_key" {
  type    = string
  default = ""
}

variable "external_secret_rdidb_key" {
  type    = string
  default = ""
}

variable "service_type" {
  description = "Service type selection"
  type        = string
  default     = "haproxy"

  validation {
    condition     = contains(["nginx", "haproxy", "lb"], var.service_type)
    error_message = "The service_type must be 'nginx', 'haproxy', or 'lb'"
  }
}
