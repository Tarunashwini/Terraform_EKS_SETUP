resource "aws_iam_role" "terra_eks_cluster_role" {
  name = "${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "eks.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "terra_eks_policy" {
  role       = aws_iam_role.terra_eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "terra_eks_cluster" {
  name     = "${var.environment}-eks"
  role_arn = aws_iam_role.terra_eks_cluster_role.arn
  version  = "1.29"

  vpc_config {
    subnet_ids              = var.private_subnets
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  # This block is required for aws_eks_access_entry
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  enabled_cluster_log_types = ["api", "audit"]
  depends_on                = [aws_iam_role_policy_attachment.terra_eks_policy]
}