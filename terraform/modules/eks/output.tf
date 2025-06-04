output "eks_oidc_provider_arn" {
  description = "OIDC provider ARN for the EKS cluster"
  value       = module.eks.oidc_provider_arn    
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "aws_eks_cluster_endpoint" {
  description = "AWS EKS cluster configuration"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_ca_cert" {
  description = "Base64 encoded CA certificate for the EKS cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
  
}

output "eks_managed_node_groups" {
  description = "EKS managed node groups configuration"
  value       = module.eks.eks_managed_node_groups
  
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the EKS cluster"
  value       = module.eks.cluster_oidc_issuer_url
  
}