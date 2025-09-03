#

variable "name" {
  description = "Deployment name"
}

variable "aws_region" {
  description = "AWS region"
  default = "us-east-2"
}

variable "public_key_file" {
  description = "Public key file"
  type = string
}

variable "tags" {
  description = "Optional tags"
  type        = map(string)
  default     = {}
}
