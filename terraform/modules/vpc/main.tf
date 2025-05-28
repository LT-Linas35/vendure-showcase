data "aws_availability_zones" "available" {}

locals {
  az_count = var.env == "prod" ? 3 : 2
  azs      = slice(data.aws_availability_zones.available.names, 0, local.az_count)
}



locals {
  private_subnets = var.env == "prod" ? [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
    ] : [
    "10.0.1.0/24"
  ]

  public_subnets = var.env == "prod" ? [
    "10.0.10.0/24",
    "10.0.20.0/24",
    "10.0.30.0/24"
    ] : [
    "10.0.10.0/24",
    "10.0.20.0/24"
  ]

  database_subnets = var.env == "prod" ? [
    "10.0.11.0/24",
    "10.0.22.0/24",
    "10.0.33.0/24"
    ] : [
    "10.0.11.0/24",
    "10.0.22.0/24"
  ]
}

##############################################################################################################################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                    = "Vendure-vpc"
  cidr                    = "10.0.0.0/16"
  map_public_ip_on_launch = true

  azs = local.azs

  private_subnets    = local.private_subnets
  public_subnets     = local.public_subnets
  database_subnets   = local.database_subnets
  single_nat_gateway = var.env == "dev" ? true : false

  enable_nat_gateway = true
  #  enable_vpn_gateway = true

  tags = {
    Terraform                = "true"
    Environment              = var.env
    "karpenter.sh/discovery" = "Vendure-Cluster"
  }
}

##############################################################################################################################