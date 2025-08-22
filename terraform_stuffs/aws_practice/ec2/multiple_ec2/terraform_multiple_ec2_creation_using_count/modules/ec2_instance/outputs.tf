# modules/ec2_instance/outputs.tf

output "instance_id" {
  value = aws_instance.instance[*].id
}

output "public_ip" {
  value = aws_instance.instance[*].public_ip
}
