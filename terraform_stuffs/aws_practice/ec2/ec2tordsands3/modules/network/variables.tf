variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "CIDR block for the private subnet"
  type        = list(string)
}

variable "public_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = list(string)
}

variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = list(string)
}
