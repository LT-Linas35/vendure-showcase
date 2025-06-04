variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = ""
}


variable "vpc_vpc_id" {
  description = "VPC ID for the AWS Load Balancer Controller"
  type        = string  
}

variable "aws_eks_cluster_endpoint" {
  description = "AWS EKS cluster endpoint"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cluster_ca_cert" {
  description = "Base64 encoded CA certificate for the EKS cluster"
  type        = string
  default     = ""
  sensitive   = true
}

variable "eks_managed_node_groups" {
  description = "EKS managed node groups configuration"
  type        = any
}

variable "AmazonEKSPodIdentityExternalDNSRole" {
  description = "ARN of the IAM role for the External DNS"
  type        = any
  default     = "" 
}

  
variable "jenkins_cognito_cliend_id" {
  description = "Client ID for the Jenkins Cognito user pool client"
  type        = string
  default     = ""
  sensitive   = true
}

variable "jenkins_cognito_secret" {
  description = "Client secret for the Jenkins Cognito user pool client"
  type        = string
  default     = ""
  sensitive   = true
}

variable "argocd_cognito_client_id" {
  description = "Client ID for the ArgoCD Cognito user pool client"
  type        = string
  default     = ""
  sensitive   = true
}

variable "argocd_cognito_secret" {
  description = "Client secret for the ArgoCD Cognito user pool client"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cognito_user_pool_id" {
  description = "ID of the Cognito user pool"
  type        = string
  default     = ""  
  sensitive   = true
}

variable "vault_unseal_role" {
  description = "Vault unseal role"
  type        = string  
}