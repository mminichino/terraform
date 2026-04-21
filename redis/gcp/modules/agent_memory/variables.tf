#

variable "server_chart_version" {
  type    = string
  default = "0.2.1"
}

variable "demo_chart_version" {
  type    = string
  default = "0.3.0"
}

variable "namespace" {
  type    = string
}

variable "redis_service" {
  type    = string
}

variable "redis_port" {
  type    = number
}

variable "domain_name" {
  type    = string
}

variable "external_secret_store" {
  type    = string
}

variable "redis_secret_key" {
  type    = string
}

variable "password_secret_key" {
  type    = string
}

variable "openai_secret_key" {
  type    = string
}

variable "tavily_secret_key" {
  type    = string
}

variable "storage_class" {
  type    = string
  default = "premium-rwo"
}
