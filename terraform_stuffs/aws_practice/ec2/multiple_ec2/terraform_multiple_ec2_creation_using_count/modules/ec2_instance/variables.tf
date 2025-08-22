# modules/ec2_instance/variables.tf


# modules/ec2_instance/variables.tf

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1
}


variable "ami" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "Instance type for the EC2 instance"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair to use"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with the instance"
  type        = list(string)
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
}

variable "root_volume_type" {
  description = "Root volume type (e.g., gp2, gp3)"
  type        = string
}

variable "tags" {
  description = "Tags to assign to the instance"
  type        = map(string)
}
