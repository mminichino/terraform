#

variable "name" {
  description = "Name of the client deployment"
  type        = string
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
}

variable "gcp_zone_name" {
  type = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "node_count" {
  description = "Number of redis nodes to create"
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "Machine type for the redis nodes"
  type        = string
  default     = "n2-standard-8"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 128
}

variable "data_volume_size" {
  description = "The data volume size"
  default     = 256
  type        = number
}

variable "public_key_file" {
  description = "Public key file for SSH access"
  type        = string
}

variable "private_key_file" {
  type = string
}

variable "gcp_user" {
  description = "GCP user for SSH access"
  type        = string
  default     = "ubuntu"
}

variable "admin_user" {
  description = "Redis admin username"
  type        = string
  default     = "admin@redis.com"
}

variable "redis_distribution" {
  description = "Redis Enterprise distribution tar file"
  type = string
}

variable "labels" {
  description = "A map of labels to assign to the resources"
  type        = map(string)
  default     = {}
}
