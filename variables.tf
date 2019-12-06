variable "inventory_version" {
  description = "Inventory file version"
}

variable "provider" {
  description = "AWS provider"
  default     = "aws"
}

variable "aws_region" {
  description = "AWS region where to deploy the cluster"
  default     = "us-west-2"
}

variable "ssh_private_key_file" {
  description = "Path to the SSH private key"
  default     = ""
}

variable "ssh_public_key_file" {
  description = "Path to the SSH public key"
}

variable "inventory_path" {
  description = "Path to the inventory file"
}

variable "ssh_user" {
  description = "The SSH user that should be used for accessing the nodes over SSH"
  default     = "centos"
}

variable "konvoy_version" {
  description = "The version of Konvoy that provisioned the cluster"
}

variable "cluster_name" {
  description = "The name of the provisioned cluster"
}

variable "cluster_name_random_string" {
  description = "Add a random string to the cluster name"
  default     = true
}

variable "aws_tags" {
  description = "Add custom tags to all resources"
  type        = "map"
  default     = {}
}

variable "aws_availability_zones" {
  type        = "list"
  description = "Availability zones to be used"
  default     = ["us-west-2c"]
}

variable "public_subnet_ids" {
  type        = "list"
  description = "Subnet to be used for public access"
  default     = []
}

variable "vpc_id" {
  description = "Pre-existing vpc to use"
  default     = ""
}

variable "vpc_route_table_id" {
  description = "Pre-existing vpc route table to use"
  default     = ""
}

variable "vpc_internet_gateway_id" {
  description = "Pre-existing vpc internet gateway to use"
  default     = ""
}

variable "create_vpc_internet_gateway" {
  description = "Allows for disabling creating the Internet Gateway."
  default     = true
}

variable "create_vpc_endpoints" {
  description = "Allows for disabling creating the VPC Endpoints."
  default     = true
}

variable "admin_cidr_blocks" {
  type        = "list"
  description = "Admin CIDR blocks that can access the cluster from outside"
  default     = ["0.0.0.0/0"]
}

variable "create_private_subnets" {
  description = "If a worker pool has no subnetIDs then we should create private subnets for it."
  default     = true
}

variable "create_iam_instance_profile" {
  description = "If any of the node pools has no instanceProfile defined then we should create private subnets for it."
  default     = true
}
