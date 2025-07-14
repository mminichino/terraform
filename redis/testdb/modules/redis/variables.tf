#

variable "aws_region" {
  description = "AWS region"
}

variable "aws_zone" {
  description = "AWS zone"
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
}

variable "subnet_block" {
  description = "Subnet CIDR"
}

variable "machine_type" {
  description = "Machine Type"
  default     = "t2.micro"
}

variable "root_volume_size" {
  description = "The root volume size"
  default     = "50"
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
