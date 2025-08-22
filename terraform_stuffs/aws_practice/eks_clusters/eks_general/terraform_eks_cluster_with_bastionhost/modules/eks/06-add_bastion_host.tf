
resource "aws_eks_access_entry" "eks_access_entry" {
  cluster_name  = aws_eks_cluster.cluster_quickops.name
  principal_arn = var.bastion_host_role_arn
  type          = "STANDARD"
  tags = {
    Name       = format("%s-cluster", var.cluster_name)
    created_by = var.created_by
  }
}

resource "aws_eks_access_policy_association" "eks_access_entry_policy_association" {
  cluster_name  = aws_eks_cluster.cluster_quickops.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.bastion_host_role_arn
  
  access_scope {
    type = "cluster"
  }

}
