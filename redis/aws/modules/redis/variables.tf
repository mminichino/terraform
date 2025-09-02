#

variable "environment_id" {
  description = "Environment id"
  type = string
}

variable "environment_name" {
  description = "Environment name"
  type = string
}

variable "name_prefix" {
  description = "Name prefix"
  type = string
}

variable "aws_region" {
  description = "AWS region"
  default = "us-east-2"
}

variable "aws_vpc_id" {
  description = "AWS VPC id"
  type = string
}

variable "parent_domain" {
  description = "Parent DNS domain"
  type = string
}

variable "aws_vpc_cidr" {
  description = "VPC CIDR"
  type = string
}

variable "aws_subnet_id_list" {
  description = "Subnet id list"
  type = list(string)
}

variable "aws_key_name" {
  description = "AWS key name"
  type = string
}

variable "redis_machine_type" {
  description = "Machine Type"
  default     = "m5.2xlarge"
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

variable "private_key_file" {
  description = "Private key file"
  type = string
}

variable "admin_password" {
  description = "Redis admin password"
  type = string
}

variable "ec2_instance_role" {
  description = "AWS role with EC2 instance profile for S3 access"
  type        = string
}

variable "redis_distribution" {
  description = "Redis Enterprise distribution tar file"
  type = string
}
