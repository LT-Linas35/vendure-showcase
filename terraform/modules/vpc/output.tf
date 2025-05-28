output "vpc_database_subnets" {
  description = "List of database subnets in the VPC"
  value       = module.vpc.database_subnets
}

output "vpc_public_subnets" {
  description = "List of public subnets in the VPC"
  value       = module.vpc.public_subnets
}

output "vpc_private_subnets" {
  description = "List of private subnets in the VPC"
  value       = module.vpc.private_subnets  
}

output "vpc_vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_default_security_group_id" {
  description = "Default security group ID for the VPC"
  value       = module.vpc.default_security_group_id
}