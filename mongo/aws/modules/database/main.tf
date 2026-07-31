# Deploy MongoDB Enterprise replica set

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
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

resource "random_password" "password" {
  length      = 16
  special     = false
  upper       = true
  lower       = true
  numeric     = true
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
}

# Shared keyfile for replica-set internal auth (must be 6-1024 chars)
resource "random_password" "keyfile" {
  length  = 64
  special = false
}

data "aws_route53_zone" "public_zone" {
  name = var.parent_domain
}

data "aws_ec2_instance_type" "machine_type" {
  instance_type = var.mongo_machine_type
}

resource "aws_key_pair" "key_pair" {
  key_name   = "${var.name}-mongo-key-pair"
  public_key = file("~/.ssh/${var.public_key_file}")

  tags = merge(var.tags, {
    Name = "${var.name}-key-pair"
  })
}

locals {
  cluster_name    = var.name
  cluster_domain  = "${local.cluster_name}.${data.aws_route53_zone.public_zone.name}"
  cpu_count       = data.aws_ec2_instance_type.machine_type.default_vcpus
  memory_mib      = data.aws_ec2_instance_type.machine_type.memory_size
  mongodb_tarball = "mongodb-linux-x86_64-enterprise-ubuntu2204-${var.mongodb_version}.tgz"
  mongodb_url     = "https://downloads.mongodb.com/linux/${local.mongodb_tarball}"
  mongosh_tarball = "mongosh-${var.mongosh_version}-linux-x64.tgz"
  mongosh_url     = "https://downloads.mongodb.com/compass/${local.mongosh_tarball}"
}

resource "aws_security_group" "mongo_sg" {
  name        = "${var.name}-mongo-sg"
  description = "MongoDB Enterprise replica set inbound traffic"
  vpc_id      = var.aws_vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.aws_vpc_cidr]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.mongo_port
    to_port     = var.mongo_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-mongo-sg"
  })
}

resource "aws_instance" "mongo_nodes" {
  count                       = var.node_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.mongo_machine_type
  key_name                    = aws_key_pair.key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.mongo_sg.id]
  subnet_id                   = var.aws_subnet_id_list[count.index % length(var.aws_subnet_id_list)]
  associate_public_ip_address = true

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

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/${var.private_key_file}")
    host        = self.public_ip
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/mongo.sh", {
      mongodb_url     = local.mongodb_url
      mongodb_version = var.mongodb_version
      mongosh_url     = local.mongosh_url
      mongosh_version = var.mongosh_version
      repl_set_name   = var.repl_set_name
      mongo_port      = var.mongo_port
      keyfile         = random_password.keyfile.result
    })
    destination = "/tmp/mongo.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/mongo.sh",
      "sudo /tmp/mongo.sh > /tmp/mongo_install.log 2>&1",
    ]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-mongo-${count.index + 1}"
  })
}

resource "aws_route53_record" "host_records" {
  count   = var.node_count
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = "mongo${count.index + 1}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.mongo_nodes[count.index].public_ip]

  depends_on = [aws_instance.mongo_nodes]
}

locals {
  primary_node_private_ip = var.node_count > 0 ? aws_instance.mongo_nodes[0].private_ip : null
  primary_node_public_ip  = var.node_count > 0 ? aws_instance.mongo_nodes[0].public_ip : null
  instance_hostnames      = [for fqdn in aws_route53_record.host_records[*].fqdn : trimsuffix(fqdn, ".")]
  member_endpoints        = [for node in aws_instance.mongo_nodes : format("%s:%d", node.private_ip, var.mongo_port)]
}

resource "null_resource" "init_replica_set" {
  count = var.node_count > 0 ? 1 : 0

  triggers = {
    node_ids         = join(",", aws_instance.mongo_nodes[*].id)
    member_endpoints = join(",", local.member_endpoints)
    repl_set_name    = var.repl_set_name
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/${var.private_key_file}")
    host        = aws_instance.mongo_nodes[0].public_ip
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/init_replica_set.sh", {
      members       = join(",", local.member_endpoints)
      repl_set_name = var.repl_set_name
      mongo_port    = var.mongo_port
      password      = random_password.password.result
      admin_user    = "admin"
    })
    destination = "/tmp/init_replica_set.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init_replica_set.sh",
      "/tmp/init_replica_set.sh",
    ]
  }

  depends_on = [
    aws_instance.mongo_nodes,
    aws_route53_record.host_records,
  ]
}
