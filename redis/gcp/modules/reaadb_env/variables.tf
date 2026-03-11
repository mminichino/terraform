#

variable "name" {
  type    = string
  default = "reaadb"
}

variable "reaadb_chart_version" {
  type    = string
  default = "0.2.1"
}

variable "tls" {
  type    = bool
  default = true
}

variable "localDomain" {
  type    = string
}

variable "remoteDomain" {
  type    = string
}

variable "username" {
  type    = string
  default = "admin@redis.com"
}

variable "namespace" {
  type    = string
}

variable "localName" {
  type    = string
}

variable "remoteName" {
  type    = string
}

variable "localClusterName" {
  type    = string
}

variable "remoteClusterName" {
  type    = string
}

variable "localNamespace" {
  type    = string
}

variable "remoteNamespace" {
  type    = string
}

variable "memory" {
  type    = string
  default = "1GB"
}

variable "port" {
  type    = number
  default = 12012
}

variable "shards" {
  type    = number
  default = 1
}

variable "external_secret_store" {
  type    = string
}

variable "cluster_key" {
  type    = string
}

variable "reaadb_key" {
  type    = string
}
