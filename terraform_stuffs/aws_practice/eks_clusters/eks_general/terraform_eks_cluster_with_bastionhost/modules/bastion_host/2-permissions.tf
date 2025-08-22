resource "aws_iam_policy" "eks_describe_policy" {
  name        = format("%s-eks-describe-policy-bh", var.cluster_name)
  description = "IAM policy to allow describing EKS clusters for bastion host"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "VisualEditor0",
        Effect   = "Allow",
        Action   = "eks:DescribeCluster",
        Resource = "*"
      }
    ]
  })
  tags = {
    Name       = format("%s-cluster", var.cluster_name)
    created_by = var.created_by
  }
}

resource "aws_iam_role" "eks_describe_role" {
  name = format("%s-empty-role-bh", var.cluster_name)
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Name       = format("%s-cluster", var.cluster_name)
    created_by = var.created_by
  }
  depends_on = [aws_iam_policy.eks_describe_policy]
}

resource "aws_iam_role_policy_attachment" "attach_bh" {
  policy_arn = aws_iam_policy.eks_describe_policy.arn
  role       = aws_iam_role.eks_describe_role.name
  depends_on = [aws_iam_policy.eks_describe_policy, aws_iam_role.eks_describe_role]

}
resource "aws_iam_instance_profile" "bh_instance_profile" {
  name       = format("%s-bh-instance-profile-bh", var.cluster_name)
  role       = aws_iam_role.eks_describe_role.name
  depends_on = [aws_iam_role_policy_attachment.attach_bh]
}


