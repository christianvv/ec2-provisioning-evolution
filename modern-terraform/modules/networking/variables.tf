variable "project_name" {
  description = "Name prefix used for tagging all resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
}
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per AZ"
  type        = list(string)
}

variable "admin_cidr" {
  description = "CIDR block allowed to SSH into the bastion host"
  type        = string
}
