#

variable "aws_region" {
  description = "AWS region"
  default = "us-east-2"
}

variable "subnet_list" {
  description = "AWS Subnet List"
  type = list(string)
  default = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "vpc_id" {
  description = "AWS VPC ID"
  type = string
}

variable "environment_name" {
  description = "Environment name"
}

variable "ssh_key" {
  description = "Admin SSH key"
}

variable "ssh_private_key" {
  description = "Admin SSH private key"
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
