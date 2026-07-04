output "instance_ids" {
  description = "IDs of all instances keyed by purpose"
  value       = { for k, v in aws_instance.devops_tools : k => v.id }
}
