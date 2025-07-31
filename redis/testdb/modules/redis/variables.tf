#

variable "aws_region" {
  description = "AWS region"
  default = "us-east-2"
}

variable "availability_zones" {
  description = "AWS availability zone List"
  type = list(string)
  default = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "public_subnets" {
  description = "Select public subnets"
  type        = bool
  default     = false
}

variable "parent_domain" {
  description = "Parent DNS domain"
  type = string
}

variable "vpc_id" {
  description = "AWS VPC ID"
  type = string
}

variable "environment_name" {
  description = "Environment name"
}

variable "key_pair" {
  description = "Admin SSH key pair"
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
  default     = "128"
}

variable "root_volume_type" {
  description = "The root volume type"
  default     = "gp3"
}

variable "root_volume_iops" {
  description = "The root volume IOPS"
  default     = "3000"
}

variable "node_count" {
  description = "Node count"
  default     = 3
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
