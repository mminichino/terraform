#

variable "domain_name" {
  type = string
}

variable "tls_secret" {
  type = string
  default = ""
}

variable "namespace" {
  type    = string
  default = "redis"
}

variable "name" {
  type = string
  default = "redis-enterprise-cluster"
}

variable "cpu" {
  type = string
  default = "4"
}

variable "memory" {
  type = string
  default = "8Gi"
}

variable "mode_count" {
  type = number
  default = 3
}

variable "storage_class" {
  type    = string
  default = "standard"
}

variable "volume_size" {
  type = string
  default = "32Gi"
}

variable "service_type" {
  description = "Service type selection"
  type        = string
  default     = "nginx"

  validation {
    condition     = contains(["nginx", "haproxy", "lb"], var.service_type)
    error_message = "The service_type must be 'nginx', 'haproxy', or 'lb'"
  }
}
