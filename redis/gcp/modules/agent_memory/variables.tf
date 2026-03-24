#

variable "server_chart_version" {
  type    = string
  default = "0.2.1"
}

variable "demo_chart_version" {
  type    = string
  default = "0.2.5"
}

variable "namespace" {
  type    = string
}

variable "redis_service" {
  type    = string
}

variable "redis_port" {
  type    = string
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
