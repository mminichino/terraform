#

variable "name_prefix" {
  description = "Name prefix"
}

variable "aws_region" {
  description = "AWS region"
  default = "us-east-2"
}

variable "cidr_block" {
  description = "VPC CIDR"
  default = "10.55.0.0/16"
}
