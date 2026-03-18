#

variable "databases" {
  type = list(object({
    name   = string
    port   = number
    memory = optional(string, "1GB")
    shards = optional(number, 1)
    tls    = optional(bool, false)
  }))
}

variable "ingressEnabled" {
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

variable "external_secret_store" {
  type    = string
}

variable "cluster_key" {
  type    = string
}

variable "reaadb_key" {
  type    = string
}
