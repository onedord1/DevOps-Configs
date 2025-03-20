provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "../../modules/networks/vpc"
  vpc_cidr        = var.vpc_cidr_block
  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  cluster_name    = var.cluster_name 
}

module "iam" {
  source = "../../modules/iam"
  cluster_name = var.cluster_name
}

module "eks" {
  source = "../../modules/eks"
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  private_subnets = module.vpc.private_subnets
#   aws_iam_role    = module.iam.aws_iam_role
}

