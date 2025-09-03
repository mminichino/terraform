#

variable "name" {
  description = "Deployment name"
}

variable "aws_region" {
  description = "AWS region"
  default = "us-east-2"
}

variable "aws_short_region" {
  description = "AWS short region"
  default = "use2"
}

variable "cidr_block" {
  description = "VPC CIDR"
  default = "10.55.0.0/16"
}

variable "tags" {
  description = "Optional tags"
  type        = map(string)
  default     = {}
}
