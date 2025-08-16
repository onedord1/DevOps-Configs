variable "aws_region" {
  description = "Value of the regions"
  type        = string
  default     = "ap-southest-1"
}

variable "cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  type        = string
  default     = "10.0.0.0/16"
}
variable "instance_type" {
  description = "Value of the regions"
  type        = string
  default     = "t2.micro"
}
variable "allowed_cidr_blocks" {
  type    = list(any)
  default = ["0.0.0.0/0"]
}
variable "availability_zones" {
  type    = list(any)
  default = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
}
variable "database_name" {
  description = "Value of the regions"
  type        = string
  default     = "empdb"
}
variable "database_user" {
  description = "Value of the regions"
  type        = string
  default     = "admin"
}
variable "database_port" {
  description = "Value of the regions"
  type        = string
  default     = "3306"
}
variable "database_password" {
  description = "Value of the regions"
  type        = string
  default     = "admin123456"
}
variable "amis" {
  type = map(any)
  default = {
    "us-east-1" = "ami-0dc2d3e4c0f9ebd18"
    "us-east-2" = "ami-0ba62214afa52bec7"
  }
}
variable "instance_name" {
  description = "Value of the regions"
  type        = string
  default     = "Praful_Portfolio_WebServer"
}
