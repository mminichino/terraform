#

variable "credential_file" {
  type = string
}

variable "name" {
  description = "Name of the client deployment"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
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
  description = "Number of client nodes to create"
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "Machine type for the client nodes"
  type        = string
  default     = "n2-standard-8"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 128
}

variable "public_key_file" {
  description = "Public key file for SSH access"
  type        = string
}

variable "gcp_user" {
  description = "GCP user for SSH access"
  type        = string
  default     = "ubuntu"
}

variable "labels" {
  description = "A map of labels to assign to the resources"
  type        = map(string)
  default     = {}
}
