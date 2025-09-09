#

variable "public_ip" {
  type = string
}

variable "private_key_file" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "uid" {
  type    = number
  default = 1
}

variable "memory_size" {
  type    = number
  default = 1073741824
}

variable "name" {
  type    = string
  default = "testdb"
}

variable "port" {
  type    = number
  default = 12000
}

variable "replication" {
  type    = bool
  default = false
}

variable "eviction" {
  type    = bool
  default = false
}
