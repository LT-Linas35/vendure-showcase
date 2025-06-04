
variable "env" {
  type        = string
  description = "Deployment environment"
}

module "db" {
  source                        = "./modules/postgres"
  env                           = var.env
  vpc_database_subnets          = module.vpc.vpc_database_subnets
  vpc_default_security_group_id = module.vpc.vpc_default_security_group_id
}

module "vpc" {
  source = "./modules/vpc"
  env    = var.env
}

module "eks" {
  source                                     = "./modules/eks"
  env                                        = var.env
  vpc_public_subnets                         = module.vpc.vpc_public_subnets
  vpc_private_subnets                        = module.vpc.vpc_private_subnets
  vpc_vpc_id                                 = module.vpc.vpc_vpc_id
  AmazonEKSPodIdentityAmazonEBSCSIDriverRole = aws_iam_role.AmazonEKSPodIdentityAmazonEBSCSIDriverRole.arn
  AWSLoadBalancerControllerIAMPolicy         = aws_iam_policy.AWSLoadBalancerControllerIAMPolicy.arn
  AllowExternalDNSUpdates                    = aws_iam_policy.AllowExternalDNSUpdates.arn
}

module "karpenter" {
  source                = "./modules/karpenter"
  env                   = var.env
  eks_oidc_provider_arn = module.eks.eks_oidc_provider_arn
}

module "route53" {
  source                  = "./modules/route53"
  db_db_instance_endpoint = module.db.db_instance_endpoint
}

module "cognito" {
  source = "./modules/cognito"
}

module "helm" {
  source                              = "./modules/helm"
  eks_cluster_name                    = module.eks.eks_cluster_name
  vpc_vpc_id                          = module.vpc.vpc_vpc_id
  aws_eks_cluster_endpoint            = module.eks.aws_eks_cluster_endpoint
  cluster_ca_cert                     = module.eks.cluster_ca_cert
  eks_managed_node_groups             = module.eks.eks_managed_node_groups
  AmazonEKSPodIdentityExternalDNSRole = aws_iam_role.AmazonEKSPodIdentityExternalDNSRole.arn
  jenkins_cognito_cliend_id           = module.cognito.jenkins_cognito_cliend_id
  jenkins_cognito_secret              = module.cognito.jenkins_cognito_secret
  argocd_cognito_client_id            = module.cognito.argocd_cognito_client_id
  argocd_cognito_secret               = module.cognito.argocd_cognito_secret
  cognito_user_pool_id                = module.cognito.cognito_user_pool_id
  vault_unseal_role                   = aws_iam_role.vault_unseal_role.arn
  providers = {
    helm = helm
  }

  depends_on = [module.eks]
}

data "aws_eks_cluster" "eks" {
  name       = module.eks.eks_cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "eks" {
  name       = module.eks.eks_cluster_name
  depends_on = [module.eks]
}

data "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_role" "external_dns_irsa" {
  name = "eks-external-dns"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.eks.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:external-dns"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "route53_permissions" {
  role       = aws_iam_role.external_dns_irsa.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess" # arba custom
}


resource "kubernetes_service_account" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns_irsa.arn
    }
  }
}

resource "kubernetes_namespace" "vendure" {
  metadata {
    annotations = {
      name = "vendure-showcase"
    }

    labels = {
      mylabel = "label-value"
    }

    name = "vendure"
  }
}

resource "kubernetes_secret" "vendure_config" {
  metadata {
    name      = "vendure-config"
    namespace = "vendure"
  }

  type = "Opaque"

  data = {
    PORT          = "3000"
    COOKIE_SECRET = "HvW6FEfJmVwO46uJhQiFXA"
    DB_HOST       = module.db.db_instance_endpoint
    DB_PORT       = "5432"
    DB_NAME       = "vendure"
    DB_USERNAME   = "superadmin"
    DB_PASSWORD   = "superadmin"
    DB_SCHEMA     = "public"
    APP_ENV       = var.env
    synchronize   = "false"
    HOST_NAME     = "0.0.0.0"
  }
  depends_on = [kubernetes_namespace.vendure]
}


resource "aws_dynamodb_table" "vault_table" {
  name         = "vault-storage"
  hash_key       = "Path"
  range_key      = "Key"
  billing_mode = "PAY_PER_REQUEST"
  
  attribute {
    name = "Path"
    type = "S"
  }
 
  attribute {
    name = "Key"
    type = "S"
  }
 
  tags = {
    Name        = "vault-dynamodb-table"
    Environment = "prod"
  }
}


resource "aws_iam_policy" "vault_kms_unseal" {
  name        = "vault-kms-unseal"
  description = "Allows Vault to use KMS key for auto-unseal"
  path        = "/"

  policy = jsonencode({
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "Statement1",
			"Effect": "Allow",
			"Action": [
				"kms:Decrypt",
				"kms:Encrypt",
				"kms:GenerateDataKey",
				"kms:DescribeKey"
			],
			"Resource": [
				"arn:aws:kms:eu-west-2:975050322104:key/2d2687c3-c0fb-4561-b43f-79512a68742d"
			]
		}
	]
})

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}


resource "aws_iam_role" "vault_unseal_role" {
  name = "vault-irsa-unseal-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement : [
      {
        Effect = "Allow",
        Principal : {
          Federated : data.aws_iam_openid_connect_provider.eks.arn
        },
        Action : "sts:AssumeRoleWithWebIdentity",
        Condition : {
          StringEquals : {
            "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:vault:vault"
          }
        }
      }
    ]
  })
}



resource "aws_iam_role_policy_attachment" "vault_kms_attach" {
  role       = aws_iam_role.vault_unseal_role.name
  policy_arn = aws_iam_policy.vault_kms_unseal.arn
}



resource "aws_iam_policy" "vault_dynamodb_storage" {
  name        = "vault-dynamodb-storage"
  description = "Allows Vault to use DynamoDB for storage backend"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:DescribeLimits",
          "dynamodb:DescribeTimeToLive",
          "dynamodb:ListTagsOfResource",
          "dynamodb:DescribeReservedCapacityOfferings",
          "dynamodb:DescribeReservedCapacity",
          "dynamodb:ListTables",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:CreateTable",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:GetRecords",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem",
          "dynamodb:Scan",
          "dynamodb:DescribeTable",
          "dynamodb:UpdateTable",
          "dynamodb:allowUpdates"
        ],
        Resource = [
          aws_dynamodb_table.vault_table.arn,
        ]
      }
    ]
  })

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

resource "aws_iam_role_policy_attachment" "vault_dynamo_attach" {
  role       = aws_iam_role.vault_unseal_role.name
  policy_arn = aws_iam_policy.vault_dynamodb_storage.arn
}


resource "aws_iam_role" "jenkins_ecr_role" {
  name = "jenkins-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement: [{
      Effect = "Allow",
      Principal: {
        Federated: data.aws_iam_openid_connect_provider.eks.arn
      },
      Action: "sts:AssumeRoleWithWebIdentity",
      Condition: {
        StringEquals: {
          "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:jenkins:jenkins"
        }
      }
    }]
  })
}


resource "aws_iam_role_policy_attachment" "ecr_access" {
  role       = aws_iam_role.jenkins_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}
