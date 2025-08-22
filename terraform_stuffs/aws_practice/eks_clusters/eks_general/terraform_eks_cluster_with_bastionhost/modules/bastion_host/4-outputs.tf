output "bh_role" {
  description = "bastion host role"
  value       = aws_iam_role.eks_describe_role
}

output "bh_instance" {
  description = "bastion host instance"
  value       = aws_instance.bh_instance
}

output "aws_sg_ssh" {
  description = "security group of bastion host"
  value       = aws_security_group.allow_ssh
}