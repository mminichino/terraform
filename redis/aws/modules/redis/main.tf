# Deploy Redis

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "random_string" "password" {
  length           = 8
  special          = false
}

data "aws_route53_zone" "public_zone" {
  name = var.parent_domain
}

resource "aws_key_pair" "key_pair" {
  key_name   = "${var.name}-redis-key-pair"
  public_key = file("~/.ssh/${var.public_key_file}")

  tags = merge(var.tags, {
    Name = "${var.name}-key-pair"
  })
}

resource "aws_security_group" "redis_sg" {
  name        = "${var.name}-redis-sg"
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

  tags = merge(var.tags, {
    Name = "${var.name}-redis-sg"
  })
}

data "aws_iam_instance_profile" "ec2_s3_profile" {
  name = var.ec2_instance_role
}

locals {
  cluster_domain = "${var.name}.${data.aws_route53_zone.public_zone.name}"
}

resource "aws_instance" "redis_nodes" {
  count                       = var.node_count
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.redis_machine_type
  key_name                    = aws_key_pair.key_pair.key_name
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

  user_data_base64 = base64encode(templatefile("${path.module}/scripts/redis.sh", {
    software_version = var.software_version
    bucket           = var.bucket
  }))

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/${var.private_key_file}")
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait > /dev/null 2>&1",
    ]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-host-${count.index + 1}"
  })
}

resource "aws_route53_record" "host_records" {
  count   = var.node_count
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = "node${count.index + 1}.${var.name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.redis_nodes[count.index].public_ip]
  depends_on = [aws_instance.redis_nodes]
}

resource "aws_route53_record" "ns_record" {
  count   = var.node_count > 0 ? 1 : 0
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = var.name
  type    = "NS"
  ttl     = 300
  records = [for i in range(var.node_count) : "node${i + 1}.${local.cluster_domain}"]
  depends_on = [aws_instance.redis_nodes]
}

locals {
  primary_node_private_ip = var.node_count > 0 ? aws_instance.redis_nodes[0].private_ip : null
  primary_node_public_ip = var.node_count > 0 ? aws_instance.redis_nodes[0].public_ip : null
  api_public_base_url = var.node_count > 0 ? "https://${aws_instance.redis_nodes[0].public_ip}:9443" : null
  instance_hostnames = [for i in range(var.node_count) : "node${i + 1}.${var.name}.${var.parent_domain}"]
  admin_urls = [for i in range(var.node_count) : "https://node${i + 1}.${var.name}.${var.parent_domain}:8443"]
}

resource "null_resource" "create_cluster" {
  count = var.node_count > 0 ? 1 : 0

  triggers = {
    node_ids = join(",", aws_instance.redis_nodes.*.id)
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/${var.private_key_file}")
    host        = aws_instance.redis_nodes[0].public_ip
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/create_cluster.sh", {
      cluster_name = var.name
      domain_name  = local.cluster_domain
      admin_user   = var.admin_user
      password     = random_string.password.id
      license      = replace(var.license, "\n", "\\n")
    })
    destination = "/tmp/create_cluster.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/create_cluster.sh",
      "/tmp/create_cluster.sh"
    ]
  }

  depends_on = [aws_route53_record.ns_record, aws_route53_record.host_records]
}

resource "null_resource" "join_cluster" {
  count = max(0, var.node_count - 1)

  triggers = {
    node_id = aws_instance.redis_nodes[count.index + 1].id
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/${var.private_key_file}")
    host        = aws_instance.redis_nodes[count.index + 1].public_ip
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/join_cluster.sh", {
      primary_node = aws_instance.redis_nodes[0].private_ip
      domain_name  = local.cluster_domain
      admin_user   = var.admin_user
      password     = random_string.password.id
    })
    destination = "/tmp/join_cluster.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/join_cluster.sh",
      "/tmp/join_cluster.sh"
    ]
  }

  depends_on = [null_resource.create_cluster]
}
