##

variable "name" {
  type = string
}

variable "api_key" {
  type = string
}

variable "secret_key" {
  type = string
}

variable "cloud" {
  type    = string
  default = "AWS"
}

variable "region" {
  type    = string
  default = "us-east-2"
}
