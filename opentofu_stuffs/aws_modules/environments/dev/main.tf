terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../../modules/networks/vpc"

  aws_region     = var.aws_region
  vpc_cidr_block = var.vpc_cidr_block
  name_prefix    = var.name_prefix
  tags           = var.tags
}

module "igw" {
  source = "../../modules/networks/igw"

  aws_region  = var.aws_region
  vpc_id      = module.vpc.vpc_id
  name_prefix = var.name_prefix
  tags        = var.tags

  depends_on = [module.vpc]
}

module "subnets" {
  source = "../../modules/networks/subnets"

  aws_region      = var.aws_region
  vpc_id          = module.vpc.vpc_id
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  name_prefix     = var.name_prefix
  tags            = var.tags

  depends_on = [module.vpc]
}