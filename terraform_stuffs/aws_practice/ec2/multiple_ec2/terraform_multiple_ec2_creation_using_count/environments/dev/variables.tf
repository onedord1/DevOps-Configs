variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1
}
# variables.tf in root module

variable "ami" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0dee22c13ea7a9a67"  # Replace with your desired AMI ID
}

variable "instance_type" {
  description = "Instance type for the EC2 instance"
  type        = string
  default     = "t2.micro"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "root_volume_type" {
  description = "Root volume type (e.g., gp2, gp3)"
  type        = string
  default     = "gp2"
}

variable "tags" {
  description = "Tags to assign to the instance"
  type        = map(string)
  default     = {
    Name = "demo_instance"
  }
}
