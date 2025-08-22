variable "allocated_storage" {
  description = "The allocated storage size for the RDS instance in GB."
  type        = number
}

variable "engine" {
  description = "The database engine to use, e.g., mysql, postgres."
  type        = string
}

variable "engine_version" {
  description = "The version of the database engine."
  type        = string
}

variable "instance_class" {
  description = "The instance type of the RDS instance."
  type        = string
}

variable "db_name" {
  description = "The name of the database."
  type        = string
}

variable "username" {
  description = "The master username for the database."
  type        = string
}

variable "password" {
  description = "The master password for the database."
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "List of subnet IDs for the RDS instance."
  type        = list(string)
}

variable "security_group_id" {
  description = "The security group ID to attach to the RDS instance."
  type        = string
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot when deleting the RDS instance."
  type        = bool
  default     = true
}

variable "rds_instance_identifier" {
  description = "Unique identifier for the RDS instance"
  type        = string
}