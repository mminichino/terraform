# Deploy Redis

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

data "aws_ami" "centos" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS Stream 9*"]
  }

  filter {
    name = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["125523088429"]
}

data "aws_ami" "ol" {
  most_recent = true

  filter {
    name   = "name"
    values = ["OL8.9-x86_64-HVM-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["131827586825"]
}

locals {
  aws_image = {
    ubuntu = data.aws_ami.ubuntu.id
    centos = data.aws_ami.centos.id
    ol     = data.aws_ami.ol.id
  }
}

resource "aws_key_pair" "key_pair" {
  key_name   = "${var.name}-key-pair"
  public_key = file("~/.ssh/${var.public_key_file}")

  tags = merge(var.tags, {
    Name = "${var.name}-key-pair"
  })
}

resource "aws_security_group" "rdbms_sg" {
  name        = "${var.name}-rdbms-sg"
  description = "RDBMS node inbound traffic"
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

  ingress {
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 33060
    to_port          = 33060
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 1521
    to_port          = 1521
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 1433
    to_port          = 1433
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
    Name = "${var.name}-rdbms-sg"
  })
}

data "aws_iam_instance_profile" "ec2_s3_profile" {
  name = var.ec2_instance_role
}

data "aws_ec2_instance_type" "instance_type" {
  instance_type = var.machine_type
}

resource "aws_instance" "rdbms_nodes" {
  count                       = var.node_count
  ami                         = local.aws_image[var.image]
  instance_type               = var.machine_type
  key_name                    = aws_key_pair.key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.rdbms_sg.id]
  subnet_id                   = var.aws_subnet_id_list[count.index % length(var.aws_subnet_id_list)]
  associate_public_ip_address = true
  iam_instance_profile        = data.aws_iam_instance_profile.ec2_s3_profile.name

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    iops        = var.root_volume_iops
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_type = "gp3"
    volume_size = data.aws_ec2_instance_type.instance_type.memory_size / 1024
    iops        = 10000
    throughput  = 600
  }

  ebs_block_device {
    device_name = "/dev/sdc"
    volume_type = "gp3"
    volume_size = var.data_volume_size
    iops        = var.data_volume_iops
    throughput  = var.data_volume_throughput
  }

  ebs_block_device {
    device_name = "/dev/sdd"
    volume_type = "gp3"
    volume_size = var.data_volume_size
    iops        = var.data_volume_iops
    throughput  = var.data_volume_throughput
  }

  user_data_base64 = base64encode(file("${path.module}/scripts/cloud_init.sh"))

  tags = merge(var.tags, {
    Name = "${var.name}-rdbms-${count.index + 1}"
  })
}
