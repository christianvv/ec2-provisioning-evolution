output "private_subnet_ids" {
  description = "IDs of available private subnets"
  value       = aws_subnet.private[*].id
}

output "private_compute_sg_id" {
  description = "ID of security group for private instances"
  value       = aws_security_group.private_compute.id
}
