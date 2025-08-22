variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "ec2_role_arn" {
  description = "The ARN of the IAM role assigned to the EC2 instance"
  type        = string
}
