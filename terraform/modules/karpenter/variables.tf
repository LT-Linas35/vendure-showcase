variable "env" {
    description = "Environment type (e.g., dev, prod)"
    type        = string
    default     = "dev"
}

variable "eks_oidc_provider_arn" {
    description = "ARN of the OIDC provider for the EKS cluster"
    type        = string
    default     = ""
}