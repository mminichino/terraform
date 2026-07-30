#

variable "name" {
  description = "Deployment name"
  type        = string
}

variable "aws_vpc_id" {
  description = "AWS VPC id"
  type        = string
}

variable "parent_domain" {
  description = "Parent DNS domain"
  type        = string
}

variable "aws_vpc_cidr" {
  description = "VPC CIDR"
  type        = string
}

variable "aws_subnet_id_list" {
  description = "Subnet id list"
  type        = list(string)
}

variable "public_key_file" {
  description = "Public key file"
  type        = string
}

variable "private_key_file" {
  description = "Private key file"
  type        = string
}

variable "redis_machine_type" {
  description = "EC2 instance type for Redis nodes"
  type        = string
  default     = "m6a.2xlarge"
}

variable "root_volume_size" {
  description = "The root volume size in GB"
  type        = number
  default     = 64
}

variable "root_volume_type" {
  description = "The root volume type"
  type        = string
  default     = "gp3"
}

variable "root_volume_iops" {
  description = "The root volume IOPS"
  type        = number
  default     = 3000
}

variable "data_volume_size" {
  description = "The data volume size in GB"
  type        = number
  default     = 256
}

variable "data_volume_iops" {
  description = "The data volume IOPS"
  type        = number
  default     = 10000
}

variable "data_volume_throughput" {
  description = "The data volume throughput in MB/s"
  type        = number
  default     = 600
}

variable "node_count" {
  description = "Number of Redis nodes"
  type        = number
  default     = 3

  validation {
    condition     = var.node_count >= 1
    error_message = "node_count must be at least 1."
  }
}

variable "shards_per_node" {
  description = "Number of master shards to run on each node"
  type        = number
  default     = 1

  validation {
    condition     = var.shards_per_node >= 1
    error_message = "shards_per_node must be at least 1."
  }
}

variable "tags" {
  description = "Optional tags"
  type        = map(string)
  default     = {}
}
