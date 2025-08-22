output "instance_id" {
  value = aws_instance.ec2_instance.id
}

output "instance_name" {
  value = var.instance_name
}

output "public_ip" {
  value = aws_instance.ec2_instance.public_ip
}

output "ec2_role_arn" {
  value = aws_iam_role.ec2_role.arn
}

output "security_group_id" {
  value = aws_instance.ec2_instance.security_groups
}

