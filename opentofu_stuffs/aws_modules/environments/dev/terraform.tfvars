aws_region = "ap-south-1"

vpc_cidr_block = "10.0.0.0/16"

name_prefix = "test"

tags = {
  Environment = "dev"
  Project     = "test"
}

public_subnets = [
  {
    cidr_block        = "10.0.1.0/24"
    availability_zone = "ap-south-1a"
  },
  {
    cidr_block        = "10.0.2.0/24"
    availability_zone = "ap-south-1b"
  }
]

private_subnets = [
  {
    cidr_block        = "10.0.3.0/24"
    availability_zone = "ap-south-1a"
  },
  {
    cidr_block        = "10.0.4.0/24"
    availability_zone = "ap-south-1b"
  },
  {
    cidr_block        = "10.0.5.0/24"
    availability_zone = "ap-south-1c"
  }
]