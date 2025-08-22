resource "aws_instance" "ec2_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id[0]
  associate_public_ip_address = true
  security_groups        = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  tags = {
    Name = var.instance_name
  }

  user_data = <<-EOT
    #!/bin/bash
    # Update the package index
    sudo apt update -y

    # Install dependencies for AWS CLI v2
    sudo apt install -y unzip curl
    sudo apt update && sudo apt install mysql-client -y

    # Download the AWS CLI v2 installer
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

    # Unzip the installer
    unzip awscliv2.zip

    # Install AWS CLI v2
    sudo ./aws/install

    # Verify the installation
    aws --version

    # Cleanup
    rm -rf awscliv2.zip aws
  EOT

  depends_on = [ aws_iam_instance_profile.ec2_instance_profile ]
}


resource "aws_iam_role" "ec2_role" {
  name = "${var.instance_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_s3_policy" {
  name   = "${var.instance_name}-s3-access"
  role   = aws_iam_role.ec2_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:GetObject", "s3:PutObject"],
        Resource = ["${var.s3_bucket_arn}", "${var.s3_bucket_arn}/*"]
      }
    ]
  })
  depends_on = [ aws_iam_role.ec2_role ]
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.instance_name}-profile"
  role = aws_iam_role.ec2_role.name
  depends_on = [ aws_iam_role.ec2_role] 
}

