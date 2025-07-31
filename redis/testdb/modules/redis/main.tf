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

data "aws_route53_zone" "domain" {
  name = var.parent_domain
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_route_tables" "public_route_tables" {
  vpc_id = var.vpc_id

  filter {
    name   = "route.gateway-id"
    values = ["igw-*"]
  }
}

data "aws_route_tables" "all_route_tables" {
  vpc_id = var.vpc_id
}

locals {
  private_route_table_ids = setsubtract(
    toset(data.aws_route_tables.all_route_tables.ids),
    toset(data.aws_route_tables.public_route_tables.ids)
  )
}

data "aws_route_table" "target_route_tables" {
  for_each = toset(var.public_subnets ? data.aws_route_tables.public_route_tables.ids : local.private_route_table_ids)
  route_table_id = each.value
}

locals {
  associated_subnet_ids = flatten([
    for rt in data.aws_route_table.target_route_tables : [
      for assoc in rt.associations : assoc.subnet_id
      if assoc.subnet_id != null
    ]
  ])
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  filter {
    name   = "subnet-id"
    values = local.associated_subnet_ids
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
    Name = "${var.environment_name}-sg"
    Environment = var.environment_name
  }
}

resource "aws_instance" "redis_nodes" {
  count                  = var.node_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.machine_type
  key_name               = var.key_pair
  vpc_security_group_ids = [aws_security_group.env_sg.id]
  subnet_id              = local.subnet_ids[count.index % length(local.subnet_ids)]

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
    Name = "host${count.index + 1}"
  }
}

resource "aws_route53_zone" "subdomain" {
  name = "${var.environment_name}.${var.parent_domain}"

  tags = {
    Name = "${var.environment_name}.${var.parent_domain}"
  }
}

resource "aws_route53_record" "subdomain_ns" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = var.environment_name
  type    = "NS"
  ttl     = 300
  records = aws_route53_zone.subdomain.name_servers
}

resource "aws_route53_record" "host_records" {
  count   = var.node_count
  zone_id = aws_route53_zone.subdomain.zone_id
  name    = "host${count.index + 1}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.redis_nodes[count.index].private_ip]
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
      environment_name = var.environment_name
      admin_password   = var.admin_password
      dns_suffix       = aws_route53_zone.subdomain.name
    })
    destination = "/tmp/setup_cluster.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup_cluster.sh",
      "/tmp/setup_cluster.sh"
    ]
  }

  depends_on = [aws_instance.redis_nodes, aws_route53_zone.subdomain]
}
