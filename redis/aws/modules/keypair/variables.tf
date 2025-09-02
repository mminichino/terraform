#

variable "aws_region" {
  description = "AWS region"
  default = "us-east-2"
}

variable "aws_short_region" {
  description = "AWS short region"
  default = "use2"
}

variable "public_key_file" {
  description = "Public key file"
  type = string
}
