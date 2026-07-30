# Deploy OSS Redis Cluster

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

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

data "aws_route53_zone" "public_zone" {
  name = var.parent_domain
}

data "aws_ec2_instance_type" "machine_type" {
  instance_type = var.redis_machine_type
}

resource "aws_key_pair" "key_pair" {
  key_name   = "${var.name}-oss-redis-key-pair"
  public_key = file("~/.ssh/${var.public_key_file}")

  tags = merge(var.tags, {
    Name = "${var.name}-key-pair"
  })
}

locals {
  cluster_name         = var.name
  cluster_domain       = "${local.cluster_name}.${data.aws_route53_zone.public_zone.name}"
  cpu_count            = data.aws_ec2_instance_type.machine_type.default_vcpus
  memory_mib           = data.aws_ec2_instance_type.machine_type.memory_size
  replicas_per_master  = 1
  instances_per_node   = var.shards_per_node * (1 + local.replicas_per_master)
  base_port            = 12000
  max_client_port      = local.base_port + local.instances_per_node - 1
  bus_base_port        = local.base_port + 10000
  max_bus_port         = local.bus_base_port + local.instances_per_node - 1
  total_master_shards  = var.node_count * var.shards_per_node
  total_replica_shards = local.total_master_shards * local.replicas_per_master
  total_shards         = local.total_master_shards + local.total_replica_shards
  # Leave 25% of instance RAM for OS / Redis overhead; split the rest across local shards.
  maxmemory_bytes = floor(local.memory_mib * 1024 * 1024 * 0.75 / local.instances_per_node)
}

resource "aws_security_group" "redis_sg" {
  name        = "${var.name}-oss-redis-sg"
  description = "OSS Redis cluster inbound traffic"
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
    from_port   = local.base_port
    to_port     = local.max_client_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = local.bus_base_port
    to_port     = local.max_bus_port
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
    Name = "${var.name}-oss-redis-sg"
  })
}

resource "aws_instance" "redis_nodes" {
  count                       = var.node_count
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.redis_machine_type
  key_name                    = aws_key_pair.key_pair.key_name
  vpc_security_group_ids      = [aws_security_group.redis_sg.id]
  subnet_id                   = var.aws_subnet_id_list[count.index % length(var.aws_subnet_id_list)]
  associate_public_ip_address = true

  lifecycle {
    precondition {
      condition     = var.node_count * var.shards_per_node >= 3
      error_message = "Redis Cluster requires at least 3 master shards (node_count * shards_per_node >= 3)."
    }

    precondition {
      condition     = var.node_count >= 2
      error_message = "At least 2 nodes are required to place replicas on different hosts from their masters."
    }
  }

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
    content = templatefile("${path.module}/scripts/redis.sh", {
      instances_per_node = local.instances_per_node
      base_port          = local.base_port
      password           = random_password.password.result
      maxmemory_bytes    = local.maxmemory_bytes
    })
    destination = "/tmp/redis.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/redis.sh",
      "sudo /tmp/redis.sh > /tmp/redis_install.log 2>&1",
    ]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-oss-redis-${count.index + 1}"
  })
}

resource "aws_route53_record" "host_records" {
  count   = var.node_count
  zone_id = data.aws_route53_zone.public_zone.zone_id
  name    = "oss-redis${count.index + 1}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.redis_nodes[count.index].public_ip]

  depends_on = [aws_instance.redis_nodes]
}

locals {
  primary_node_private_ip = var.node_count > 0 ? aws_instance.redis_nodes[0].private_ip : null
  primary_node_public_ip  = var.node_count > 0 ? aws_instance.redis_nodes[0].public_ip : null
  instance_hostnames      = [for fqdn in aws_route53_record.host_records[*].fqdn : trimsuffix(fqdn, ".")]

  # Masters first (evenly across nodes), then replicas (evenly across nodes).
  # redis-cli --cluster create takes the first total/(replicas+1) endpoints as masters.
  master_endpoints = flatten([
    for shard in range(var.shards_per_node) : [
      for node in aws_instance.redis_nodes :
      format("%s:%d", node.private_ip, local.base_port + shard)
    ]
  ])

  replica_endpoints = flatten([
    for shard in range(var.shards_per_node) : [
      for node in aws_instance.redis_nodes :
      format("%s:%d", node.private_ip, local.base_port + var.shards_per_node + shard)
    ]
  ])

  cluster_endpoints = concat(local.master_endpoints, local.replica_endpoints)
}

resource "null_resource" "create_cluster" {
  count = var.node_count > 0 ? 1 : 0

  triggers = {
    node_ids            = join(",", aws_instance.redis_nodes[*].id)
    shards_per_node     = var.shards_per_node
    replicas_per_master = local.replicas_per_master
    cluster_endpoints   = join(" ", local.cluster_endpoints)
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/${var.private_key_file}")
    host        = aws_instance.redis_nodes[0].public_ip
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/create_cluster.sh", {
      endpoints           = join(" ", local.cluster_endpoints)
      password            = random_password.password.result
      replicas_per_master = local.replicas_per_master
    })
    destination = "/tmp/create_cluster.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/create_cluster.sh",
      "/tmp/create_cluster.sh",
    ]
  }

  depends_on = [
    aws_instance.redis_nodes,
    aws_route53_record.host_records,
  ]
}
