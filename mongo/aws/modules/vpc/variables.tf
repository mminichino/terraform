#

variable "name" {
  description = "Deployment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "cidr_block" {
  description = "VPC CIDR"
  type        = string
  default     = "10.56.0.0/16"
}

variable "tags" {
  description = "Optional tags"
  type        = map(string)
  default     = {}
}
