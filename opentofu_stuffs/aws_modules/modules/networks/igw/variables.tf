variable "aws_region" {
  description = "AWS region where resources will be provisioned"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to attach the Internet Gateway"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}