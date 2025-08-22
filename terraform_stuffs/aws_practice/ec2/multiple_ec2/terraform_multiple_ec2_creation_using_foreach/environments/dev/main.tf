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
  source = "../../modules/ec2_instance"
  for_each = var.instances

  ami              = each.value.ami
  instance_type    = each.value.instance_type
  key_name         = module.key_pair.key_name
  security_group_ids = [module.security_group.security_group_id]
  root_volume_size = each.value.root_volume_size
  root_volume_type = each.value.root_volume_type
  tags             = each.value.tags
}

