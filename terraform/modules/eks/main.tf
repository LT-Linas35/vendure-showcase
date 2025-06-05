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
    "eks-pod-identity-agent" = {}
    "kube-proxy"             = {}
    "vpc-cni"                = {}
#    "external-dns" = {}
  }

  create_node_security_group = false
  # Optional
  cluster_endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = var.vpc_vpc_id
  subnet_ids               = slice(var.vpc_private_subnets, 0, min(length(var.vpc_private_subnets), (var.env == "prod" ? 3 : 1)))
  control_plane_subnet_ids = slice(var.vpc_public_subnets, 0, min(length(var.vpc_public_subnets), (var.env == "prod" ? 3 : 2)))

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t2.xlarge"]
  }

  eks_managed_node_groups = {
    data-planes = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t2.xlarge"]
      desired_size   = 1
      min_size       = 1
      max_size       = 1
      iam_role_additional_policies = {
        AWSLoadBalancerControllerIAMPolicy = var.AWSLoadBalancerControllerIAMPolicy
      }

      labels = {
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "true"
      }
    }
  }
  
  tags = {
    Environment              = var.env
    Terraform                = "true"
    "karpenter.sh/discovery" = "Vendure-Cluster"
  }
}


resource "aws_eks_addon" "aws_ebs_csi_driver" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_update = "PRESERVE"
  pod_identity_association {
    service_account = "ebs-csi-controller-sa"
    role_arn        = var.AmazonEKSPodIdentityAmazonEBSCSIDriverRole
  }
  depends_on = [ module.eks.cluster_addons ]
}