####################################################################################
#no need of  core-dns,kube-proxy will automatically be created
####################################################################################
# common oidc configuration for ebs csi and vpc-cni
data "tls_certificate" "oidc_tls" {
  url = aws_eks_cluster.cluster_quickops.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc_tls.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster_quickops.identity[0].oidc[0].issuer
  tags = {
    Name       = format("%s-cluster", var.cluster_name)
    created_by = var.created_by
  }
  depends_on = [aws_eks_node_group.private_nodegroup_1]
}


####################################################################################
### VPC-CNI
data "aws_iam_policy_document" "vpc_cni_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      identifiers = [aws_iam_openid_connect_provider.oidc_provider.arn]
      type        = "Federated"
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }
  }
  depends_on = [aws_iam_openid_connect_provider.oidc_provider]
}

resource "aws_iam_role" "vpc_cni_role" {
  assume_role_policy = data.aws_iam_policy_document.vpc_cni_assume_role_policy.json
  name               = format("%s-vpc-cni-role", var.cluster_name)
  depends_on         = [data.aws_iam_policy_document.vpc_cni_assume_role_policy]
  tags = {
    Name       = format("%s-cluster", var.cluster_name)
    created_by = var.created_by
  }
}

resource "aws_iam_role_policy_attachment" "vpc_cni_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni_role.name
  depends_on = [aws_iam_role.vpc_cni_role]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = aws_eks_cluster.cluster_quickops.name
  addon_name               = "vpc-cni"
  service_account_role_arn = aws_iam_role.vpc_cni_role.arn
  configuration_values = jsonencode({
    "enableNetworkPolicy" : "true"
  })
  depends_on = [aws_eks_cluster.cluster_quickops, aws_iam_role.vpc_cni_role]
  tags = {
    Name       = format("%s-cluster", var.cluster_name)
    created_by = var.created_by
  }
}

####################################################################################
#EBS-CSI-DRIVER
#ref: https://davegallant.ca/blog/amazon-ebs-csi-driver-terraform/

data "aws_iam_policy_document" "ebs_csi_driver_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      identifiers = [aws_iam_openid_connect_provider.oidc_provider.arn]
      type        = "Federated"
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
  }
  depends_on = [aws_iam_openid_connect_provider.oidc_provider]
}

resource "aws_iam_role" "ebs_csi_driver" {
  name               = format("%s-ebs-csi-driver-role", var.cluster_name)
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role_policy.json
  depends_on         = [data.aws_iam_policy_document.ebs_csi_driver_assume_role_policy]
  tags = {
    Name       = format("%s-cluster", var.cluster_name)
    created_by = var.created_by
  }
}

resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
  depends_on = [aws_iam_role.ebs_csi_driver]
}
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.cluster_quickops.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
  depends_on               = [aws_iam_role_policy_attachment.AmazonEBSCSIDriverPolicy]
  tags = {
    Name       = format("%s-cluster", var.cluster_name)
    created_by = var.created_by
  }
}
