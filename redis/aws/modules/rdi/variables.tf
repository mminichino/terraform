#

variable "name" {
  description = "Deployment name"
  type        = string
  default     = "rdi"
}

variable "aws_region" {
  description = "AWS region"
  default = "us-east-2"
}

variable "aws_vpc_id" {
  description = "AWS VPC id"
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

variable "public_key_file" {
  description = "Public key file"
  type = string
}

variable "rdi_machine_type" {
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

variable "rdi_node_count" {
  description = "Node count"
  default     = 0
}

variable "ec2_instance_role" {
  description = "AWS role with EC2 instance profile for S3 access"
  type        = string
}

variable "rdi_version" {
  description = "RDI version"
  type = string
}

variable "tags" {
  description = "Optional tags"
  type        = map(string)
  default     = {}
}
