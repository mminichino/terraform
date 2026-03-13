#

variable "server_chart_version" {
  type    = string
  default = "0.1.2"
}

variable "demo_chart_version" {
  type    = string
  default = "0.1.1"
}

variable "namespace" {
  type    = string
}

variable "server_url" {
  type    = string
  default = ""
}

variable "domain_name" {
  type    = string
  default = ""
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
  default = ""
}

variable "password_secret_key" {
  type    = string
  default = ""
}

variable "openai_secret_key" {
  type    = string
  default = ""
}

variable "tavily_secret_key" {
  type    = string
  default = ""
}
