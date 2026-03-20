module "vpc" {
  source = "../../modules/vpc"
  environment     = var.environment
  vpc_cidr        = var.vpc_cidr
  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
}

module "eks" {
  source          = "../../modules/eks"
  environment     = var.environment
  private_subnets = module.vpc.terra_private_subnets
}

module "node_group" {
  source       = "../../modules/node-group"
  environment  = var.environment
  cluster_name = module.eks.cluster_name
  subnet_ids   = module.vpc.terra_private_subnets

  desired_size = var.desired_size
  min_size     = var.min_size
  max_size     = var.max_size
}

module "bastion" {
  source           = "../../modules/bastion"
  name             = "${var.environment}-bastion"
  vpc_id           = module.vpc.terra_vpc_id
  public_subnet_id = module.vpc.terra_public_subnets[0]
  allowed_ssh_cidr = concat(var.allowed_ssh_cidr, [var.vpc_cidr])
  cluster_name     = module.eks.cluster_name
}

# --- CONNECT BASTION TO EKS ---

# 1. Network: Security Group Rule to allow Bastion -> EKS on 443
resource "aws_security_group_rule" "bastion_to_eks" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = module.bastion.bastion_sg_id
}

# 2. Identity: Register Bastion IAM Role in EKS Access Entry
resource "aws_eks_access_entry" "bastion_access" {
  cluster_name      = module.eks.cluster_name
  principal_arn     = module.bastion.bastion_role_arn
  type              = "STANDARD"
}

# 3. Permissions: Associate Admin Policy with the Bastion Access Entry
resource "aws_eks_access_policy_association" "bastion_admin" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = module.bastion.bastion_role_arn

  access_scope {
    type = "cluster"
  }
}

resource "aws_iam_role" "aws_lb_controller_role" {
  name = "${var.environment}-aws-lb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          # Reference the module output here
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            # Reference the module output here
            "${replace(module.eks.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${replace(module.eks.oidc_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}


# Create the specific policy required by the LB Controller
resource "aws_iam_policy" "aws_lb_controller_additional_permissions" {
  name        = "${var.environment}-aws-lb-controller-policy"
  description = "Permissions required by the AWS Load Balancer Controller"

  # Use the official AWS JSON content here
  policy = file("${path.module}/iam_policy.json")
}

# Attach THIS policy to your role instead of the generic one
resource "aws_iam_role_policy_attachment" "aws_lb_controller_attach" {
  role       = aws_iam_role.aws_lb_controller_role.name
  policy_arn = aws_iam_policy.aws_lb_controller_additional_permissions.arn
}
