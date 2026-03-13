#

variable "chart_version" {
  type = string
  default = "0.1.0"
}

variable "namespace" {
  type = string
}

variable "redis_url" {
  type = string
}

variable "openai_key" {
  type = string
}
