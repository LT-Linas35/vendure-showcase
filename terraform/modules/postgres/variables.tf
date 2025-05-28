variable "env" {
    description = "Environment type (e.g., dev, prod)"
    type        = string
    default     = "dev"
}

variable "vpc_database_subnets" {
    description = "List of database subnets in the VPC"
    type        = list(string)
    default     = []
}

variable "vpc_default_security_group_id" {
    description = "Default security group ID for the VPC"
    type        = string
    default     = ""
}