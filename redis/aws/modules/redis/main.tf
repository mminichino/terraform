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

resource "random_string" "env_key" {
  length           = 8
  special          = false
  upper            = false
}

resource "random_string" "password" {
  length           = 16
  special          = false
}

data "aws_route53_zone" "public_zone" {
  name = var.parent_domain
}

locals {
  name_prefix    = "${var.name}-${random_string.env_key.id}"
  environment_id = random_string.env_key.id
  vpc_dns_server = cidrhost(var.aws_vpc_cidr, 2)
}

data "aws_key_pair" "key_pair" {
  key_name   = var.aws_key_name
}

resource "aws_security_group" "redis_sg" {
  name        = "${local.name_prefix}-redis-sg"
  description = "Redis Enterprise inbound traffic"
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
    from_port        = 53
    to_port          = 53
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 53
    to_port          = 53
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 6379
    to_port          = 6379
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 16379
    to_port          = 16379
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 8443
    to_port          = 8443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 9443
    to_port          = 9443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 10000
    to_port          = 19999
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
    Name = "${local.name_prefix}-redis-sg"
    Environment = var.name
  }
}

data "aws_iam_instance_profile" "ec2_s3_profile" {
  name = var.ec2_instance_role
}

resource "aws_instance" "redis_nodes" {
  count                       = var.node_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.redis_machine_type
  key_name                    = data.aws_key_pair.key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.redis_sg.id]
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
    volume_size = var.data_volume_size
    iops        = var.data_volume_iops
    throughput  = var.data_volume_throughput
  }

  user_data_base64 = base64encode(templatefile("${path.module}/scripts/rec.sh", {
    aws_region            = var.aws_region
    redis_distribution    = var.redis_distribution
    dns_server            = local.vpc_dns_server
  }))

  tags = {
    Name = "${local.name_prefix}-host-${count.index + 1}"
  }
}

resource "aws_route53_record" "host_records" {
  count   = var.node_count
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = "node${count.index + 1}.${local.environment_id}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.redis_nodes[count.index].public_ip]
  depends_on = [aws_instance.redis_nodes]
}

resource "aws_route53_record" "ns_record" {
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = local.environment_id
  type    = "NS"
  ttl     = 300
  records = [for i in range(var.node_count) : "node${i + 1}.${local.environment_id}.${data.aws_route53_zone.public_zone.name}"]
  depends_on = [aws_instance.redis_nodes]
}

resource "null_resource" "create_cluster" {
  triggers = {
    node_ips = join(" ", aws_instance.redis_nodes[*].public_ip)
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/${var.private_key_file}")
    host        = aws_instance.redis_nodes[0].public_ip
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/setup_cluster.sh", {
      node_ips         = join(" ", aws_instance.redis_nodes[*].private_ip)
      public_ips       = join(" ", aws_instance.redis_nodes[*].public_ip)
      node_azs         = join(" ", aws_instance.redis_nodes[*].availability_zone)
      environment_name = var.name
      admin_user       = var.admin_user
      admin_password   = random_string.password.id
      dns_suffix       = "${local.environment_id}.${data.aws_route53_zone.public_zone.name}"
    })
    destination = "/tmp/setup_cluster.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/ebsnvme.py"
    destination = "/tmp/ebsnvme.py"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup_cluster.sh",
      "/tmp/setup_cluster.sh"
    ]
  }

  depends_on = [aws_instance.redis_nodes, aws_route53_record.ns_record, aws_route53_record.host_records]
}
