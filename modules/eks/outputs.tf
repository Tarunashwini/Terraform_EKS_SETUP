output "cluster_name" {
  value = aws_eks_cluster.terra_eks_cluster.name
}

output "cluster_security_group_id" {
  description = "The security group ID created by the EKS cluster"
  value       = aws_eks_cluster.terra_eks_cluster.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.terra_oidc.arn
}

output "oidc_provider_url" {
  value = aws_iam_openid_connect_provider.terra_oidc.url
}