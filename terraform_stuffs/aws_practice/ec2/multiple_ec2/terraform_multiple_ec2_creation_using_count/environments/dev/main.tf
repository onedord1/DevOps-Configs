# main.tf in root module
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region     = "ap-south-1"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

# Key Pair Module
module "key_pair" {
  source   = "../../modules/key_pair"
  key_name = var.key_name
}

# Security Group Module
module "security_group" {
  source      = "../../modules/security_group"
  sg_name     = "sg_ec2"
  description = "Security group for EC2"
}

# main.tf in root module

module "ec2_instance" {
  source                 = "../../modules/ec2_instance"
  count                  = var.instance_count
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = module.key_pair.key_name
  security_group_ids     = [module.security_group.security_group_id]
  root_volume_size       = var.root_volume_size
  root_volume_type       = var.root_volume_type
  tags                   = var.tags
}
