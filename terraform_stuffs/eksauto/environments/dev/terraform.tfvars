aws_region      = "ap-south-1"
vpc_cidr_block  = "10.0.0.0/16"
azs             = ["ap-south-1a", "ap-south-1b"]
private_subnets = ["10.0.0.0/21", "10.0.8.0/21", "10.0.16.0/21"]
public_subnets  = ["10.0.24.0/23", "10.0.26.0/23", "10.0.28.0/23"]
cluster_name    = "eks-auto-demo"
cluster_version = "1.32"
