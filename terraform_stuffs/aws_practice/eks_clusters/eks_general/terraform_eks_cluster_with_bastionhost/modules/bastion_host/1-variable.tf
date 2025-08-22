variable "cluster_name" {
  description = "name of the cluster, will be the name of the VPC,should be unique"
  type        = string
}

variable "created_by" {
  description = "created by quickops metadata"
  type        = string
}

variable "aws_region" {
  description = "your aws region"
  type        = string
}

variable "bastion_host_ec2_size" {
  description = "your bastion host ec2 size"
  type        = string
}


variable "ami_id" {
  description = "ami id of your ec2 instance"
  type        = string
  default     = "ami-0dee22c13ea7a9a67"
}

variable "bh_subnet_id" {
  description = "subnet id for the bastion host"
  type        = string

}

variable "bh_vpc_id" {
  description = "vpc for the bastion host"
  type        = string
}