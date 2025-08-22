variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "CIDR block for the private subnet"
  type        = list(string)
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = list(string)
}

variable "availability_zone" {
  description = "AWS availability zone"
  type        = list(string)
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed for SSH access"
  type        = list(string)
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "Instance type for the EC2 instance"
  type        = string
}

variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
}

variable "region" {
  description = "AWS region for resources"
  type        = string
}


variable "rds_allocated_storage" {
  description = "The allocated storage size for the RDS instance in GB."
  type        = number
}

variable "rds_engine" {
  description = "The database engine to use, e.g., mysql, postgres."
  type        = string
}

variable "rds_engine_version" {
  description = "The version of the database engine."
  type        = string
}

variable "rds_instance_class" {
  description = "The instance type of the RDS instance."
  type        = string
}

variable "rds_db_name" {
  description = "The name of the database."
  type        = string
}

variable "rds_username" {
  description = "The master username for the database."
  type        = string
}

variable "rds_password" {
  description = "The master password for the database."
  type        = string
  sensitive   = true
}

variable "rds_skip_final_snapshot" {
  description = "Whether to skip the final snapshot when deleting the RDS instance."
  type        = bool
  default     = true
}
