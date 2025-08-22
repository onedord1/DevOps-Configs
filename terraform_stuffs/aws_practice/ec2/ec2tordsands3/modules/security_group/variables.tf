variable "vpc_id" {
  description = "VPC ID to associate the security group with"
  type        = string
}

variable "sg_name" {
  description = "Name of the security group"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH"
  type        = list(string)
}

# variable "security_group_id" {
#   description = "The security group ID for the EC2 instance to allow communication with RDS."
#   type        = string
# }

# variable "security_group_id" {
#   description = "The ID of the security group to which the rule should be applied"
#   type        = string
# }

