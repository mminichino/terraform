#

variable "aws_region" {
  description = "AWS region"
  default = "us-east-2"
}

variable "environment_name" {
  description = "Environment name"
}

variable "public_key_file" {
  description = "Public key file"
  type = string
}
