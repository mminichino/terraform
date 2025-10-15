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

variable "max_db_size" {
  type = number
  default = 25
}

variable "db_quantity" {
  type = number
  default = 4
}

variable "throughput_measurement" {
  type = string
  default = "operations-per-second"
}

variable "throughput" {
  type = number
  default = 25000
}
