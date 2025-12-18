#

variable "name" {
  description = "Deployment name"
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
