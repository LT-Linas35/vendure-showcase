##############################################################################################################################

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                    = "Vendure-vpc"
  cidr                    = "10.0.0.0/16"
  map_public_ip_on_launch = true

  azs = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
  database_subnets = ["10.0.11.0/24", "10.0.22.0/24", "10.0.33.0/24"]

  enable_nat_gateway = true
  #  enable_vpn_gateway = true

  tags = {
    Terraform                = "true"
    Environment              = "dev"
    "karpenter.sh/discovery" = "Vendure-Cluster"
  }
}

##############################################################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.36"

  cluster_name    = "Vendure-Cluster"
  cluster_version = "1.32"

  enable_irsa = true

  #  bootstrap_self_managed_addons = false
  cluster_addons = {
    coredns = {
      configuration_values = jsonencode({
        tolerations = [
          # Allow CoreDNS to run on the same nodes as the Karpenter controller
          # for use during cluster creation when Karpenter nodes do not yet exist
          {
            key    = "karpenter.sh/controller"
            value  = "true"
            effect = "NoSchedule"
          }
        ]
      })
    }
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
    aws-ebs-csi-driver     = {
      service_account_role_arn = "arn:aws:iam::975050322104:role/AmazonEKSPodIdentityAmazonEBSCSIDriverRole"
    }
  }
  # Optional
  cluster_endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = [module.vpc.private_subnets[0], module.vpc.private_subnets[1], module.vpc.private_subnets[2]]
  control_plane_subnet_ids = [module.vpc.public_subnets[0], module.vpc.public_subnets[1], module.vpc.public_subnets[2]]

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t2.medium"]
  }

  eks_managed_node_groups = {
    example = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t2.medium"]

      min_size     = 1
      max_size     = 2
      desired_size = 2
      labels = {
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "true"
      }
    }
  }
  tags = {
    Environment              = "dev"
    Terraform                = "true"
    "karpenter.sh/discovery" = "Vendure-Cluster"
  }
}

##############################################################################################################################

module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name           = "Vendure-Cluster"
  namespace              = "kube-system"
  enable_irsa            = true
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn
  # Name needs to match role name passed to the EC2NodeClass
  node_iam_role_use_name_prefix   = false
  node_iam_role_name              = "Vendure-Cluster"
  create_pod_identity_association = true
  enable_v1_permissions           = true


  # Attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AmazonEBSCSIDriverPolicy           = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    AmazonEKS_CNI_Policy               = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

##############################################################################################################################

