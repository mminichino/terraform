#

variable "name" {
  description = "Deployment name"
  type        = string
}

variable "aws_vpc_id" {
  description = "AWS VPC id"
  type = string
}

variable "aws_vpc_cidr" {
  description = "VPC CIDR"
  type = string
}

variable "aws_subnet_id_list" {
  description = "Subnet id list"
  type = list(string)
}

variable "public_key_file" {
  description = "Public key file"
  type = string
}

variable "machine_type" {
  description = "Machine Type"
  default     = "m5.2xlarge"
}

variable "root_volume_size" {
  description = "The root volume size"
  default     = 64
  type        = number
}

variable "root_volume_type" {
  description = "The root volume type"
  default     = "gp3"
}

variable "root_volume_iops" {
  description = "The root volume IOPS"
  default     = 3000
  type        = number
}

variable "data_volume_iops" {
  description = "The data volume IOPS"
  default     = 10000
  type        = number
}

variable "data_volume_throughput" {
  description = "The data volume throughput"
  default     = 600
  type        = number
}

variable "data_volume_size" {
  description = "The data volume size"
  default     = 256
  type        = number
}

variable "node_count" {
  description = "Node count"
  default     = 1
}

variable "ec2_instance_role" {
  description = "AWS role with EC2 instance profile for S3 access"
  type        = string
}

variable "tags" {
  description = "Optional tags"
  type        = map(string)
  default     = {}
}

variable "image" {
  description = "Image selection"
  type        = string
  default     = "ubuntu"

  validation {
    condition     = contains(["ubuntu", "ol", "centos"], var.image)
    error_message = "The image must be 'ubuntu', 'ol', or 'centos'"
  }
}
