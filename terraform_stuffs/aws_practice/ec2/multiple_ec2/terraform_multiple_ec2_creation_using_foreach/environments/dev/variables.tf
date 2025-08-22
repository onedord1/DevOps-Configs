# variables.tf in root module

variable "instances" {
  description = "Map of instance configurations"
  type = map(object({
    ami             = string
    instance_type   = string
    root_volume_size = number
    root_volume_type = string
    tags            = map(string)
  }))
  default = {
    instance1 = {
      ami             = "ami-0dee22c13ea7a9a67"
      instance_type   = "t2.micro"
      root_volume_size = 30
      root_volume_type = "gp2"
      tags = {
        Name = "demo_instance1"
      }
    },
    instance2 = {
      ami             = "ami-0dee22c13ea7a9a67"
      instance_type   = "t2.small"
      root_volume_size = 50
      root_volume_type = "gp2"
      tags = {
        Name = "demo_instance2"
      }
    }

    #more will be written here as per needs with unique config
  }
}

# variables.tf in root module

# variable "ami" {
#   description = "AMI ID for the EC2 instance"
#   type        = string
#   default     = "ami-0dee22c13ea7a9a67"  # Replace with your desired AMI ID
# }

# variable "instance_type" {
#   description = "Instance type for the EC2 instance"
#   type        = string
#   default     = "t2.micro"
# }

# variable "root_volume_size" {
#   description = "Root volume size in GB"
#   type        = number
#   default     = 30
# }

# variable "root_volume_type" {
#   description = "Root volume type (e.g., gp2, gp3)"
#   type        = string
#   default     = "gp2"
# }

# variable "tags" {
#   description = "Tags to assign to the instance"
#   type        = map(string)
#   default     = {
#     Name = "demo_instance"
#   }
# }
