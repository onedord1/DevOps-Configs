# modules/ec2_instance/main.tf

resource "aws_instance" "instance" {
  count                  = var.instance_count  # Use count here if specified
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.security_group_ids

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }

  tags = merge(var.tags, { "Name" = "${var.tags["Name"]}-${count.index}" })
}
