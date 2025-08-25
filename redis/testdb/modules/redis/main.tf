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

data "aws_route53_zone" "public_zone" {
  name = var.parent_domain
}

data "aws_route53_zone" "private_zone" {
  count        = 1
  name         = var.parent_domain
  private_zone = true
}

data "aws_availability_zones" "zones" {
  state = "available"
}

resource "random_string" "env_key" {
  length           = 8
  special          = false
  upper            = false
}

locals {
  environment_id = random_string.env_key.id
  name_prefix = "${var.environment_name}-${random_string.env_key.id}"
  vpc_dns_server = cidrhost(var.cidr_block, 2)
  has_private_zone = can(data.aws_route53_zone.private_zone[0].zone_id)
}

resource "aws_key_pair" "key_pair" {
  key_name   = "${local.name_prefix}-key-pair"
  public_key = file("~/.ssh/${var.public_key_file}")

  tags = {
    Name = "${local.name_prefix}-key-pair"
  }
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_subnet" "subnets" {
  count                   = length(data.aws_availability_zones.zones.names)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.zones.names[count.index]
  map_public_ip_on_launch = true
  depends_on              = [aws_vpc.vpc]

  tags = {
    Name = "${local.name_prefix}-subnet-${data.aws_availability_zones.zones.names[count.index]}"
    Type = "public"
  }
}

resource "aws_security_group" "redis_sg" {
  name        = "${local.name_prefix}-redis-sg"
  description = "Redis Enterprise inbound traffic"
  vpc_id      = aws_vpc.vpc.id
  depends_on  = [aws_vpc.vpc]

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [aws_vpc.vpc.cidr_block]
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
    Environment = var.environment_name
  }
}

resource "aws_security_group" "client_sg" {
  name        = "${local.name_prefix}-client-sg"
  description = "Redis Enterprise inbound traffic"
  vpc_id      = aws_vpc.vpc.id
  depends_on  = [aws_vpc.vpc]

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [aws_vpc.vpc.cidr_block]
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

  tags = {
    Name = "${local.name_prefix}-client-sg"
    Environment = var.environment_name
  }
}

resource "aws_instance" "redis_nodes" {
  count                       = var.node_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.machine_type
  key_name                    = aws_key_pair.key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.redis_sg.id]
  subnet_id                   = aws_subnet.subnets[count.index % length(aws_subnet.subnets)].id
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    iops        = var.root_volume_iops
  }

  user_data_base64 = base64encode(templatefile("${path.module}/scripts/rec.sh", {
    aws_access_key_id     = var.aws_access_key_id
    aws_secret_access_key = var.aws_secret_access_key
    aws_session_token     = var.aws_session_token
    aws_region            = var.aws_region
    redis_distribution    = var.redis_distribution
    dns_server            = local.vpc_dns_server
  }))

  tags = {
    Name = "${local.name_prefix}-host-${count.index + 1}"
  }
}

resource "aws_instance" "client_nodes" {
  count                       = var.client_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.machine_type
  key_name                    = aws_key_pair.key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.client_sg.id]
  subnet_id                   = aws_subnet.subnets[count.index % length(aws_subnet.subnets)].id
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    iops        = var.root_volume_iops
  }

  user_data_base64 = base64encode(templatefile("${path.module}/scripts/client.sh", {
    aws_access_key_id     = var.aws_access_key_id
    aws_secret_access_key = var.aws_secret_access_key
    aws_session_token     = var.aws_session_token
    aws_region            = var.aws_region
  }))

  tags = {
    Name = "${local.name_prefix}-client-${count.index + 1}"
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
  name    = var.environment_name
  type    = "NS"
  ttl     = 300
  records = [for i in range(var.node_count) : "node${i + 1}.${local.environment_id}.${data.aws_route53_zone.public_zone.name}"]
  depends_on = [aws_instance.redis_nodes]
}

resource "aws_route53_record" "private_host_records" {
  count   = local.has_private_zone ? var.node_count : 0
  zone_id = data.aws_route53_zone.private_zone[0].zone_id
  name    = "node${count.index + 1}.${local.environment_id}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.redis_nodes[count.index].private_ip]
  depends_on = [aws_instance.redis_nodes]
}

resource "aws_route53_record" "private_ns_record" {
  count   = local.has_private_zone ? 1 : 0
  zone_id = data.aws_route53_zone.private_zone[0].zone_id
  name    = var.environment_name
  type    = "NS"
  ttl     = 300
  records = [for i in range(var.node_count) : "node${i + 1}.${local.environment_id}.${data.aws_route53_zone.private_zone[0].name}"]
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
      environment_name = var.environment_name
      admin_password   = var.admin_password
      dns_suffix       = "${local.environment_id}.${data.aws_route53_zone.public_zone.name}"
    })
    destination = "/tmp/setup_cluster.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup_cluster.sh",
      "/tmp/setup_cluster.sh"
    ]
  }

  depends_on = [aws_instance.redis_nodes, aws_route53_record.ns_record, aws_route53_record.host_records]
}
