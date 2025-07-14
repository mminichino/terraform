# Deploy Redis

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_subnet" "subnet_list" {
  for_each = toset(data.aws_subnets.subnets.ids)
  id       = each.value
}

locals {
  subnet_ids = [for subnet in data.aws_subnet.subnet_list : subnet.id]
}

resource "aws_key_pair" "host_key" {
  key_name   = "${var.environment_name}-key"
  public_key = var.ssh_key
}

resource "aws_security_group" "env_sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id
  depends_on = [var.vpc_id]

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [data.aws_vpc.vpc.cidr_block]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.environment_name}-sg"
    Environment = var.environment_name
  }
}

resource "aws_instance" "redis_node" {
  count                  = var.node_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.machine_type
  key_name               = aws_key_pair.host_key.key_name
  vpc_security_group_ids = [aws_security_group.env_sg.id]
  subnet_id              = local.subnet_ids[count.index % length(local.subnet_ids)]
  depends_on             = [aws_key_pair.host_key]

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    iops        = var.root_volume_iops
  }

  tags = {
    Name = "${var.environment_name}-node-${count.index}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
    ]
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = base64decode(var.ssh_private_key)
    }
  }
}
