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

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }

  dynamic "filter" {
    for_each = length(var.availability_zones) > 0 ? [1] : []
    content {
      name   = "availability-zone"
      values = var.availability_zones
    }
  }
}

data "aws_subnet" "subnet_list" {
  for_each = toset(data.aws_subnets.subnets.ids)
  id       = each.value
}

locals {
  subnet_ids = [for subnet in data.aws_subnet.subnet_list : subnet.id]
  vpc_dns_server = cidrhost(data.aws_vpc.vpc.cidr_block, 2)
}

resource "aws_security_group" "redis_sg" {
  name        = "${var.environment_name}-redis-sg"
  description = "Redis Enterprise inbound traffic"
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
    Name = "${var.environment_name}-redis-sg"
    Environment = var.environment_name
  }
}

resource "aws_security_group" "client_sg" {
  name        = "${var.environment_name}-client-sg"
  description = "Redis Enterprise inbound traffic"
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

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.environment_name}-client-sg"
    Environment = var.environment_name
  }
}

resource "aws_instance" "redis_nodes" {
  count                       = var.node_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.machine_type
  key_name                    = var.key_pair
  vpc_security_group_ids      = [aws_security_group.redis_sg.id]
  subnet_id                   = local.subnet_ids[count.index % length(local.subnet_ids)]
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
    Name = "${var.environment_name}-host-${count.index + 1}"
  }
}

resource "aws_instance" "client_nodes" {
  count                       = var.client_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.machine_type
  key_name                    = var.key_pair
  vpc_security_group_ids      = [aws_security_group.client_sg.id]
  subnet_id                   = local.subnet_ids[count.index % length(local.subnet_ids)]
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
    dns_server            = local.vpc_dns_server
  }))

  tags = {
    Name = "${var.environment_name}-client-${count.index + 1}"
  }
}

resource "aws_route53_record" "host_records" {
  count   = var.node_count
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = "node${count.index + 1}.${var.environment_name}"
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
  records = [for i in range(var.node_count) : "node${i + 1}.${var.environment_name}.${data.aws_route53_zone.public_zone.name}"]
  depends_on = [aws_instance.redis_nodes]
}

resource "aws_route53_record" "private_host_records" {
  count   = length(data.aws_route53_zone.private_zone) > 0 ? var.node_count : 0
  zone_id = data.aws_route53_zone.private_zone[0].zone_id
  name    = "node${count.index + 1}.${var.environment_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.redis_nodes[count.index].private_ip]
  depends_on = [aws_instance.redis_nodes]
}

resource "aws_route53_record" "private_ns_record" {
  count   = length(data.aws_route53_zone.private_zone) > 0 ? 1 : 0
  zone_id = data.aws_route53_zone.private_zone[0].zone_id
  name    = var.environment_name
  type    = "NS"
  ttl     = 300
  records = [for i in range(var.node_count) : "node${i + 1}.${var.environment_name}.${data.aws_route53_zone.private_zone[0].name}"]
  depends_on = [aws_instance.redis_nodes]
}

resource "null_resource" "create_cluster" {
  triggers = {
    node_ips = join(" ", aws_instance.redis_nodes[*].private_ip)
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/${var.private_key_file}")
    host        = aws_instance.redis_nodes[0].private_ip
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/setup_cluster.sh", {
      node_ips         = join(" ", aws_instance.redis_nodes[*].private_ip)
      public_ips       = join(" ", aws_instance.redis_nodes[*].public_ip)
      node_azs         = join(" ", aws_instance.redis_nodes[*].availability_zone)
      environment_name = var.environment_name
      admin_password   = var.admin_password
      dns_suffix       = "${var.environment_name}.${data.aws_route53_zone.public_zone.name}"
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
