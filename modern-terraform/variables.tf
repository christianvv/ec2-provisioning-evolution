variable "project_name" {
  description = "Name prefix used for tagging all resources in this project"
  type        = string
  default     = "modern-terraform"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets, one per AZ"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "admin_cidr" {
  description = "CIDR block allowed to SSH into the bastion host"
  type        = string
  default     = "YOUR_IP_HERE/32"
}

variable "instances" {
  description = "Map of compute instances to provision, keyed by purpose"
  type = map(object({
    instance_type = string
  }))
  default = {
    "source-control"     = { instance_type = "t3.micro" }
    "artifact-repo"      = { instance_type = "t3.micro" }
    "directory-services" = { instance_type = "t3.micro" }
    "ci-cd"              = { instance_type = "t3.micro" }
    "monitoring"         = { instance_type = "t3.micro" }
  }
}
