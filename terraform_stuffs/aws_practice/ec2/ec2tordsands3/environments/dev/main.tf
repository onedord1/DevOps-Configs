# root/environments/dev/main.tf

provider "aws" {
  region = var.region
}

module "key_pair" {
  source   = "../../modules/key_pair"
  key_name = var.key_name
}

module "network" {
  source               = "../../modules/network"
  vpc_cidr             = var.vpc_cidr
  vpc_name             = var.vpc_name
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidr   = var.public_subnet_cidr
  availability_zone    = var.availability_zone
}

module "security_group" {
  source             = "../../modules/security_group"
  vpc_id             = module.network.vpc_id
  sg_name            = var.instance_name
  allowed_ssh_cidrs  = var.allowed_ssh_cidrs
}

module "s3" {
  source      = "../../modules/s3"
  bucket_name = var.bucket_name
  ec2_role_arn = module.ec2.ec2_role_arn
}

module "ec2" {
  source            = "../../modules/ec2"
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  key_name          = var.key_name
  subnet_id         = module.network.public_subnet_id
  security_group_id = module.security_group.security_group_id
  instance_name     = var.instance_name
  s3_bucket_arn     = module.s3.bucket_arn
}

module "rds" {
  source              = "../../modules/rds"
  rds_instance_identifier = module.ec2.instance_name
  allocated_storage   = var.rds_allocated_storage
  engine              = var.rds_engine
  engine_version      = var.rds_engine_version
  instance_class      = var.rds_instance_class
  db_name             = var.rds_db_name
  username            = var.rds_username
  password            = var.rds_password
  subnet_ids          = module.network.private_subnet_ids
  security_group_id   = module.security_group.security_group_id
  skip_final_snapshot = var.rds_skip_final_snapshot
}

