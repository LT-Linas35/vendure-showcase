variable "env" {
  type        = string
  description = "Deployment environment"
}

module "db" {
  source = "./modules/postgres"
  env    = var.env
  vpc_database_subnets = module.vpc.vpc_database_subnets
  vpc_default_security_group_id = module.vpc.vpc_default_security_group_id
}

module "vpc" {
  source = "./modules/vpc"    
  env    = var.env
}

module "eks" {
  source = "./modules/eks"
  env    = var.env
  vpc_public_subnets = module.vpc.vpc_public_subnets
  vpc_private_subnets = module.vpc.vpc_private_subnets
  vpc_vpc_id = module.vpc.vpc_vpc_id
}

module "karpenter" {
  source = "./modules/karpenter"
  env = var.env
  eks_oidc_provider_arn = module.eks.eks_oidc_provider_arn
}

module "route53" {
  source = "./modules/route53"
}

module "helm" {
  source = "./modules/helm" 
  eks_cluster_name = module.eks.eks_cluster_name
}