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

variable "proxy_policy" {
  type        = string
  default     = "all-master-shards"
  description = "Proxy policy for the database"
}

variable "shards_count" {
  type        = number
  default     = 1
  description = "Number of shards"
}

variable "shards_placement" {
  type        = string
  default     = "sparse"
  description = "Shards placement policy"
}

variable "database_type" {
  type        = string
  default     = "redis"
  description = "Type of database"
}

variable "data_persistence" {
  type        = string
  default     = "aof"
  description = "Data persistence policy"
}

variable "aof_policy" {
  type        = string
  default     = "appendfsync-every-sec"
  description = "AOF policy"
}

variable "oss_cluster" {
  type        = bool
  default     = false
  description = "Enable OSS cluster API"
}

variable "oss_cluster_endpoint" {
  type        = string
  default     = "ip"
  description = "Preferred endpoint type for OSS cluster API"
}

variable "oss_cluster_type" {
  type        = string
  default     = "internal"
  description = "Preferred IP type for OSS cluster API"
}
