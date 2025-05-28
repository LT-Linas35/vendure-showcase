variable "env" {
    description = "Environment type (e.g., dev, prod)"
    type        = string
    default     = "dev"
}

variable "vpc_public_subnets" {
    description = "List of public subnets in the VPC"
    type        = list(string)
    default     = []
}

variable "vpc_private_subnets" {
    description = "List of private subnets in the VPC"
    type        = list(string)
    default     = []
}

variable "vpc_vpc_id" {
    description = "VPC ID where the EKS cluster will be deployed"
    type        = string
    default     = ""    
}