#

variable "postgres_version" {
  type    = string
  default = "1.0.13"
}

variable "secret_store" {
  type = string
}

variable "password_key" {
  type = string
}

variable "storage_class" {
  type = string
}

variable "dns_domain" {
  type = string
}
