#

variable "name" {
  description = "The name of the VPC."
  type        = string
}

variable "gcp_project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "gcp_region" {
  description = "The GCP region for the subnet."
  type        = string
}

variable "cidr_block" {
  description = "The CIDR block for the subnet."
  type        = string
  default     = "10.55.0.0/16"
}

variable "services_range" {
  type    = string
  default = "192.168.1.0/24"
}

variable "pod_range" {
  type    = string
  default = "192.168.64.0/22"
}
