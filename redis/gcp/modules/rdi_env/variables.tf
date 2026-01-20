#

variable "rdi_sys_config_version" {
  type    = string
  default = "0.1.1"
}

variable "rdi_db_secrets_version" {
  type    = string
  default = "0.1.1"
}

variable "rdi_di_cli_version" {
  type    = string
  default = "0.1.4"
}

variable "rdi_version" {
  type    = string
  default = "1.15.1"
}

variable "source_username" {
  type    = string
  default = "postgres"
}

variable "target_username" {
  type    = string
  default = "default"
}

variable "external_secrets_enabled" {
  type    = string
  default = true
}

variable "external_secret_store" {
  type = string
}

variable "source_key" {
  type = string
}

variable "target_key" {
  type = string
}

variable "connection_username" {
  type    = string
  default = "default"
}

variable "rdidb_password_key" {
  type = string
}

variable "rdi_token_key" {
  type = string
}

variable "rdidb_port" {
  type    = number
  default = 12001
}

variable "rdidb" {
  type    = string
  default = "rdidb"
}

variable "rdidb_namespace" {
  type = string
}

variable "domain_name" {
  type = string
}
