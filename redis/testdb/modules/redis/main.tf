# Deploy Ubuntu

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_key_pair" "host_key" {
  key_name   = "${var.environment_name}-key"
  public_key = var.ssh_key
}

resource "aws_vpc" "env_vpc" {
  cidr_block = var.cidr_block

  tags = {
    Name = "${var.environment_name}-vpc"
    Environment = var.environment_name
  }
}

resource "aws_internet_gateway" "env_gw" {
  vpc_id = aws_vpc.env_vpc.id

  tags = {
    Name = "${var.environment_name}-gw"
    Environment = var.environment_name
  }
}

resource "aws_route_table" "env_rt" {
  vpc_id = aws_vpc.env_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.env_gw.id
  }

  tags = {
    Name = "${var.environment_name}-rt"
    Environment = var.environment_name
  }
}

resource "aws_subnet" "env_subnet" {
  vpc_id     = aws_vpc.env_vpc.id
  cidr_block = var.subnet_block
  availability_zone = var.aws_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment_name}-subnet-1"
    Environment = var.environment_name
  }
}

resource "aws_route_table_association" "env_rta" {
  subnet_id      = aws_subnet.env_subnet.id
  route_table_id = aws_route_table.env_rt.id
}

resource "aws_security_group" "env_sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.env_vpc.id
  depends_on = [aws_vpc.env_vpc]

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [aws_vpc.env_vpc.cidr_block]
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

resource "aws_instance" "ubuntu" {
  count                  = var.node_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.machine_type
  key_name               = aws_key_pair.host_key.key_name
  vpc_security_group_ids = [aws_security_group.env_sg.id]
  subnet_id              = aws_subnet.env_subnet.id
  availability_zone      = var.aws_zone
  depends_on             = [aws_vpc.env_vpc, aws_key_pair.host_key]

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
      "sudo apt install -y nginx",
      "sudo sh -c 'echo Hello_World > /var/www/html/index.html'",
    ]
    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = base64decode(var.ssh_private_key)
    }
  }
}
