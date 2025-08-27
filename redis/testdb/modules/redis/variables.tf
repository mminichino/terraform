#

variable "aws_region" {
  description = "AWS region"
  default = "us-east-2"
}

variable "parent_domain" {
  description = "Parent DNS domain"
  type = string
}

variable "environment_name" {
  description = "Environment name"
}

variable "cidr_block" {
  description = "VPC CIDR"
  default = "10.55.0.0/16"
}

variable "machine_type" {
  description = "Machine Type"
  default     = "m5.xlarge"
}

variable "root_volume_size" {
  description = "The root volume size"
  default     = 64
  type        = number
}

variable "root_volume_type" {
  description = "The root volume type"
  default     = "gp3"
}

variable "root_volume_iops" {
  description = "The root volume IOPS"
  default     = 3000
  type        = number
}

variable "data_volume_iops" {
  description = "The data volume IOPS"
  default     = 10000
  type        = number
}

variable "data_volume_throughput" {
  description = "The data volume throughput"
  default     = 600
  type        = number
}

variable "data_volume_size" {
  description = "The data volume size"
  default     = 256
  type        = number
}

variable "node_count" {
  description = "Node count"
  default     = 3
}

variable "client_count" {
  description = "Client count"
  default     = 1
}

variable "public_key_file" {
  description = "Public key file"
  type = string
}

variable "private_key_file" {
  description = "Private key file"
  type = string
}

variable "admin_password" {
  description = "Redis admin password"
  type = string
}

variable "aws_access_key_id" {
  description = "AWS Access Key ID"
  type        = string
  sensitive   = true
  default     = null
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key"
  type        = string
  sensitive   = true
  default     = null
}

variable "aws_session_token" {
  description = "AWS Session Token"
  type        = string
  sensitive   = true
  default     = null
}

variable "redis_distribution" {
  description = "Redis Enterprise distribution tar file"
  type = string
}
