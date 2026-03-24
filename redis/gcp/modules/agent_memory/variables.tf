#

variable "server_chart_version" {
  type    = string
  default = "0.2.0"
}

variable "demo_chart_version" {
  type    = string
  default = "0.2.3"
}

variable "namespace" {
  type    = string
}

variable "server_service" {
  type    = string
}

variable "server_namespace" {
  type    = string
}

variable "server_port" {
  type    = number
}

variable "domain_name" {
  type    = string
}

variable "external_secret_enabled" {
  type    = bool
  default = true
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
