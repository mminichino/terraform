# Deploy VPC

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "zones" {
  state = "available"
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

resource "aws_route_table" "default" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  tags = {
    Name = "${var.name_prefix}-rt"
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
    Name = "${var.name_prefix}-subnet-${data.aws_availability_zones.zones.names[count.index]}"
    Type = "public"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.subnets)

  subnet_id      = aws_subnet.subnets[count.index].id
  route_table_id = aws_route_table.default.id
}
