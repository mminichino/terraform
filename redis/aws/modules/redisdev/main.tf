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

resource "random_string" "password" {
  length           = 16
  special          = false
}

data "aws_route53_zone" "public_zone" {
  name = var.parent_domain
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
  ami                         = data.aws_ami.ubuntu.id
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

  user_data_base64 = base64encode(templatefile("${path.module}/scripts/rec.sh", {
    aws_region            = var.aws_region
    redis_distribution    = var.redis_distribution
    dns_server            = local.vpc_dns_server
  }))

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/${var.private_key_file}")
    host        = aws_instance.redis_nodes[0].public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait > /dev/null 2>&1",
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

resource "null_resource" "create_cluster" {
  count = var.node_count > 0 ? 1 : 0

  triggers = {
    node_ip = aws_instance.redis_nodes[0].public_ip
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/${var.private_key_file}")
    host        = aws_instance.redis_nodes[0].public_ip
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/create_cluster.sh", {
      cluster_name = var.name
      domain_name  = local.cluster_domain
      admin_user   = var.admin_user
      password     = random_string.password.id
    })
    destination = "/tmp/create_cluster.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/create_cluster.sh",
      "/tmp/create_cluster.sh"
    ]
  }

  depends_on = [aws_instance.redis_nodes, aws_route53_record.ns_record, aws_route53_record.host_records]
}

resource "null_resource" "join_cluster" {
  count = max(0, var.node_count - 1)

  triggers = {
    node_ip = aws_instance.redis_nodes[count.index + 1].public_ip
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
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

  depends_on = [aws_instance.redis_nodes, null_resource.create_cluster]
}

# data "http" "wait_for_api" {
#   count = var.node_count > 0 ? 1 : 0
#
#   url    = "https://${aws_instance.redis_nodes[0].public_ip}:8443"
#   method = "GET"
#   insecure = true
#
#   retry {
#     attempts = 300
#     min_delay_ms = 1000
#     max_delay_ms = 1000
#   }
#
#   depends_on = [aws_instance.redis_nodes, aws_route53_record.ns_record]
# }
#
# resource "null_resource" "pause" {
#   provisioner "local-exec" {
#     command = "sleep 15"
#   }
#   depends_on = [data.http.wait_for_api]
# }
#
# data "http" "primary_node" {
#   count = var.node_count > 0 ? 1 : 0
#
#   url    = "https://${aws_instance.redis_nodes[0].public_ip}:9443/v1/bootstrap/create_cluster"
#   method = "POST"
#   insecure = true
#
#   request_headers = {
#     Content-Type = "application/json"
#   }
#
#   retry {
#     attempts = 120
#     min_delay_ms = 500
#     max_delay_ms = 1000
#   }
#
#   request_body = jsonencode({
#     action = "create_cluster",
#     cluster = {
#       name = var.name,
#       nodes = []
#     },
#     node = {
#       bigstore_enabled = true,
#       paths = {
#         persistent_path = "/data/persistent",
#         ephemeral_path  = "/data/temp",
#         bigstore_path   = "/data/flash"
#       },
#       identity = {
#         addr    = aws_instance.redis_nodes[0].private_ip,
#         external_addr = [
#           aws_instance.redis_nodes[0].public_ip
#         ],
#         rack_id = aws_instance.redis_nodes[0].availability_zone
#       }
#     },
#     policy = {
#       rack_aware = true
#     },
#     dns_suffixes = [
#       {
#         name = local.env_domain,
#         cluster_default = true
#       },
#       {
#         name = "internal.${local.env_domain}",
#         use_internal_addr = true
#       }
#     ],
#     credentials = {
#       username = var.admin_user,
#       password = random_string.password.id
#     },
#     license = ""
#   })
#
#   depends_on = [aws_instance.redis_nodes, null_resource.pause]
# }
#
# resource "null_resource" "wait" {
#   provisioner "local-exec" {
#     command = "sleep 30"
#   }
#   depends_on = [data.http.primary_node]
# }
#
# data "http" "secondary_nodes" {
#   count = max(0, var.node_count - 1)
#
#   url    = "https://${aws_instance.redis_nodes[count.index + 1].public_ip}:9443/v1/bootstrap/join_cluster"
#   method = "POST"
#   insecure = true
#
#   request_headers = {
#     Content-Type = "application/json"
#   }
#
#   retry {
#     attempts = 120
#     min_delay_ms = 500
#     max_delay_ms = 1000
#   }
#
#   request_body = jsonencode({
#     action = "join_cluster",
#     cluster = {
#       nodes = [aws_instance.redis_nodes[0].private_ip]
#     },
#     node = {
#       bigstore_enabled = true,
#       paths = {
#         persistent_path = "/data/persistent",
#         ephemeral_path  = "/data/temp",
#         bigstore_path   = "/data/flash"
#       },
#       identity = {
#         addr    = aws_instance.redis_nodes[count.index + 1].private_ip,
#         external_addr = [
#           aws_instance.redis_nodes[count.index + 1].public_ip
#         ],
#         rack_id = aws_instance.redis_nodes[count.index + 1].availability_zone
#       }
#     },
#     policy = {
#       rack_aware = true
#     },
#     credentials = {
#       username = var.admin_user,
#       password = random_string.password.id
#     }
#   })
#
#   depends_on = [data.http.primary_node, null_resource.wait]
# }
#
# resource "null_resource" "validate_primary" {
#   count = var.node_count > 0 ? 1 : 0
#
#   triggers = {
#     primary_status = data.http.primary_node[0].status_code
#     validation_time = timestamp()
#   }
#
#   lifecycle {
#     precondition {
#       condition     = data.http.primary_node[0].status_code == 200
#       error_message = "Primary failed with status: ${data.http.primary_node[0].status_code}: ${data.http.primary_node[0].response_body}"
#     }
#   }
#
#   depends_on = [data.http.primary_node]
# }
#
# resource "null_resource" "validate_secondary" {
#   count = length(data.http.secondary_nodes)
#
#   triggers = {
#     secondary_status = data.http.secondary_nodes[count.index].status_code
#     validation_time = timestamp()
#   }
#
#   lifecycle {
#     precondition {
#       condition     = data.http.secondary_nodes[count.index].status_code == 200
#       error_message = "Node ${count.index + 2} notification failed with status: ${data.http.secondary_nodes[count.index].status_code}: ${data.http.secondary_nodes[count.index].response_body}"
#     }
#   }
#
#   depends_on = [data.http.secondary_nodes]
# }
