# Deploy Client

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

locals {
  vpc_dns_server = cidrhost(var.aws_vpc_cidr, 2)
}

resource "aws_key_pair" "key_pair" {
  key_name   = "${var.name}-key-pair"
  public_key = file("~/.ssh/${var.public_key_file}")

  tags = merge(var.tags, {
    Name = "${var.name}-key-pair"
  })
}

resource "aws_security_group" "client_sg" {
  name        = "${var.name}-client-sg"
  description = "Redis client node inbound traffic"
  vpc_id      = var.aws_vpc_id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [var.aws_vpc_cidr]
  }

  ingress {
    from_port        = 22
    to_port          = 22
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

  tags = merge(var.tags, {
    Name = "${var.name}-client-sg"
  })
}

resource "aws_instance" "client_nodes" {
  count                       = var.client_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.client_machine_type
  key_name                    = aws_key_pair.key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.client_sg.id]
  subnet_id                   = var.aws_subnet_id_list[count.index % length(var.aws_subnet_id_list)]
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    iops        = var.root_volume_iops
  }

  user_data_base64 = base64encode(templatefile("${path.module}/scripts/client.sh", {
    aws_region            = var.aws_region
    dns_server            = local.vpc_dns_server
  }))

  tags = merge(var.tags, {
    Name = "${var.name}-client-${count.index + 1}"
  })
}
