variable "project_name" {
  description = "Name prefix used for tagging all resources"
  type        = string
}

variable "instances" {
  description = "Map of compute instances to provision, keyed by purpose"
  type = map(object({
    instance_type = string
  }))
}

variable "private_subnet_ids" {
  description = "IDs of private subnets"
  type        = list(string)
}

variable "private_compute_sg_id" {
  description = "ID of security group for private instances"
  type        = string
}
