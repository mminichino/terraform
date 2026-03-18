#

variable "namespace" {
  type    = string
}

variable "server_url" {
  type    = string
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
