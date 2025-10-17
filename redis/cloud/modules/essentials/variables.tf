##

variable "name" {
  type = string
}

variable "cloud" {
  type = string
  default = "GCP"

  validation {
    condition = contains(["AWS", "GCP", "Azure"], var.cloud)
    error_message = "Cloud must be AWS or GCP or Azure"
  }
}

variable "region" {
  default = "us-central1"
}

variable "replication" {
  type    = bool
  default = true
}

variable "persistence" {
  type    = string
  default = "aof-every-1-second"
}

variable "plan" {
  type    = string
  default = "Single-Zone_Persistence_5GB"
}

variable "modules" {
  type    = list(string)
  default = ["RedisJSON", "RediSearch", "RedisTimeSeries", "RedisBloom"]
}
