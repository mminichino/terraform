terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
    }
  }

  required_version = ">= 0.14.0"
}
