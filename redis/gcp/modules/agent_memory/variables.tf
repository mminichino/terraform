#

variable "chart_version" {
  type    = string
  default = "0.1.1"
}

variable "namespace" {
  type    = string
}

variable "external_secret_enabled" {
  type    = bool
  default = true
}

variable "external_secret_store" {
  type    = string
  default = ""
}

variable "redis_secret_key" {
  type    = string
  default = ""
}

variable "openai_secret_key" {
  type    = string
  default = ""
}
