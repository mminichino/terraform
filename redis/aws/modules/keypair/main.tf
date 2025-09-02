# Environment

provider "aws" {
  region = var.aws_region
}

resource "random_string" "env_key" {
  length           = 8
  special          = false
  upper            = false
}

locals {
  name_prefix = "${var.aws_short_region}-${random_string.env_key.id}"
}

resource "aws_key_pair" "key_pair" {
  key_name   = "${local.name_prefix}-key-pair"
  public_key = file("~/.ssh/${var.public_key_file}")

  tags = {
    Name = "${local.name_prefix}-key-pair"
  }
}
