##

variable "name" {
  type = string
}

variable "cloud" {
  type = string
  default = "AWS"

  validation {
    condition = contains(["AWS", "GCP"], var.cloud)
    error_message = "Cloud must be AWS or GCP"
  }
}

variable "region" {
  default = "us-east-2"
}

variable "cidr" {
  type = string
  default = "10.0.0.0/24"
}

variable "replication" {
  type = bool
  default = true
}

variable "memory_gb" {
  type = number
  default = 1
}

variable "modules" {
  type    = list(string)
  default = ["RedisJSON", "RediSearch", "RedisTimeSeries", "RedisBloom"]
}

variable "persistence" {
  type = string
  default = "aof-every-write"
}

variable "throughput_measurement" {
  type = string
  default = "operations-per-second"
}

variable "throughput" {
  type = number
  default = 25000
}

variable "tags" {
  description = "Optional tags"
  type        = map(string)
  default     = {}
}
