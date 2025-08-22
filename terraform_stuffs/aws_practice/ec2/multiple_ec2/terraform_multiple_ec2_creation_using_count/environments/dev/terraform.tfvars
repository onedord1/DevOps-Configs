# terraform.tfvars
ami             = "ami-0dee22c13ea7a9a67"  # Specify a different AMI if needed
instance_type   = "t2.micro"
root_volume_size = 30
root_volume_type = "gp2"
tags = {
  Name = "demo_instance"
}
