# aws_sg_ssh_id
###################################
# allow bastion host security group cluster
resource "aws_security_group" "allow_sg_bh" {
  name        = format("%s-allow-bastionhost-sg", var.cluster_name)
  vpc_id      = var.bh_vpc_id
  description = "Allow bastion host security group traffic to this security group"
  tags = {
    Name       = format("%s-cluster", var.cluster_name)
    created_by = var.created_by
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.aws_sg_ssh]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#############
resource "aws_iam_role" "eks-cluster-role" {
  name = format("%s-eks-cluster-role", var.cluster_name)
  tags = {
    Name       = format("%s-cluster", var.cluster_name)
    created_by = var.created_by
  }

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-role.name
  depends_on = [ aws_iam_role.eks-cluster-role ]
  
}

resource "aws_eks_cluster" "cluster_quickops" {
  name     = var.cluster_name
  version  = var.EKS_Kubernetes_Version
  role_arn = aws_iam_role.eks-cluster-role.arn

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }
  vpc_config {
    subnet_ids = [
      var.subnet_id_private_1,
      var.subnet_id_private_2
    ]
    security_group_ids      = [aws_security_group.allow_sg_bh.id]
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
  tags = {
    Name       = format("%s-cluster", var.cluster_name)
    created_by = var.created_by
  }
}