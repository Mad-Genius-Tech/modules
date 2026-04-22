output "instance_id" {
  description = "EC2 instance ID of the GitHub runner"
  value       = module.ec2.id
}

output "instance_arn" {
  description = "ARN of the GitHub runner EC2 instance"
  value       = module.ec2.arn
}

output "private_ip" {
  description = "Private IP address of the GitHub runner"
  value       = module.ec2.private_ip
}

output "security_group_id" {
  description = "Security group ID of the GitHub runner"
  value       = module.sg.security_group_id
}

output "iam_role_name" {
  description = "IAM role name of the GitHub runner"
  value       = module.ec2.iam_role_name
}

output "iam_role_arn" {
  description = "IAM role ARN of the GitHub runner"
  value       = module.ec2.iam_role_arn
}

output "iam_instance_profile_arn" {
  description = "IAM instance profile ARN of the GitHub runner"
  value       = module.ec2.iam_instance_profile_arn
}

output "instance_state" {
  description = "Current state of the EC2 instance"
  value       = aws_ec2_instance_state.this.state
}
