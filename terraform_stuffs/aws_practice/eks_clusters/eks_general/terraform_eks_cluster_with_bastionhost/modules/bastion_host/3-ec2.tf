#public subnet
resource "aws_security_group" "allow_ssh" {
  name        = format("%s-allow-ssh-bh", var.cluster_name)
  vpc_id      = var.bh_vpc_id
  description = "Allow SSH inbound traffic"
  tags = {
    Name       = format("%s-cluster", var.cluster_name)
    created_by = var.created_by
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere (change this for security)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Create an EC2 Instance
resource "aws_instance" "bh_instance" {
  ami                    = var.ami_id
  instance_type          = var.bastion_host_ec2_size
  iam_instance_profile   = aws_iam_instance_profile.bh_instance_profile.name
  subnet_id              = var.bh_subnet_id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  user_data              = <<-EOF
                #!/bin/bash
                LATEST_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
                sudo apt install unzip -y
                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                unzip awscliv2.zip
                sudo ./aws/install

                curl -LO "https://storage.googleapis.com/kubernetes-release/release/$LATEST_VERSION/bin/linux/amd64/kubectl"
                chmod +x ./kubectl
                sudo mv ./kubectl /usr/local/bin
              EOF

  depends_on = [aws_security_group.allow_ssh, aws_iam_instance_profile.bh_instance_profile]
  tags = {
    Name       = format("%s bastion host", var.cluster_name)
    created_by = var.created_by
  }

}




