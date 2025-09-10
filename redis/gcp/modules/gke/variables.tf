#

variable "credential_file" {
  type = string
}

variable "name" {
  description = "The name for the GKE cluster."
  type        = string
  default     = "gke-cluster"
}

variable "gcp_project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "gcp_region" {
  description = "The GCP region for the GKE cluster."
  type        = string
}

variable "network_name" {
  description = "The name of the VPC network to deploy the GKE cluster in."
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet to deploy the GKE cluster in."
  type        = string
}

variable "node_count" {
  description = "The number of nodes in the GKE cluster's node pool."
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "The machine type for the GKE nodes."
  type        = string
  default     = "n2-standard-8"
}

variable "labels" {
  description = "A map of labels to assign to the resources."
  type        = map(string)
  default     = {}
}
