#

variable "credential_file" {
  type = string
}

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
