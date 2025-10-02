#

variable "name" {
  type = string
}

variable "namespace" {
  type    = string
  default = "redis"
}

variable "domain_name" {
  type = string
}

variable "cluster" {
  type = string
  default = "redis-enterprise-cluster"
}

variable "memory" {
  type    = string
  default = "1GB"
}

variable "replication" {
  type    = bool
  default = true
}

variable "shards" {
  type    = number
  default = 1
}

variable "placement" {
  type    = string
  default = "dense"
}

variable "port" {
  type    = number
  default = 12000
}

variable "eviction" {
  type    = string
  default = "noeviction"
}

variable "modules" {
  type    = list(string)
  default = ["ReJSON", "search", "timeseries"]
}

variable "ingress_service" {
  type    = string
  default = "ingress-nginx-controller"
}

variable "ingress_namespace" {
  type    = string
  default = "ingress-nginx"
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
