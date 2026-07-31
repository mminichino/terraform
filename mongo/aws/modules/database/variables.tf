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
  description = "Public key file (under ~/.ssh/)"
  type        = string
}

variable "private_key_file" {
  description = "Private key file (under ~/.ssh/)"
  type        = string
}

variable "mongo_machine_type" {
  description = "EC2 instance type for MongoDB nodes"
  type        = string
  default     = "m6a.xlarge"
}

variable "node_count" {
  description = "Number of MongoDB replica set members (1 primary + node_count-1 secondaries)"
  type        = number
  default     = 3

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 50
    error_message = "node_count must be between 1 and 50."
  }
}

variable "mongodb_version" {
  description = "MongoDB Enterprise version to download"
  type        = string
  default     = "8.3.7"
}

variable "mongosh_version" {
  description = "mongosh version to download"
  type        = string
  default     = "2.9.2"
}

variable "repl_set_name" {
  description = "Replica set name"
  type        = string
  default     = "rs0"
}

variable "mongo_port" {
  description = "mongod listen port"
  type        = number
  default     = 27017
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

variable "tags" {
  description = "Optional tags"
  type        = map(string)
  default     = {}
}
