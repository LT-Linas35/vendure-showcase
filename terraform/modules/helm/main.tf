
#################################################################################################

resource "helm_release" "karpenter" {
  #  depends_on = [var.eks]
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.5.0"

  namespace = "kube-system"

  set {
    name  = "settings.clusterName"
    value = var.eks_cluster_name
  }
  set {
    name  = "controller.resources.requests.cpu"
    value = "1"
  }
  set {
    name  = "controller.resources.requests.memory"
    value = "1Gi"
  }
  set {
    name  = "controller.resources.limits.cpu"
    value = "1"
  }
  set {
    name  = "controller.resources.limits.memory"
    value = "1Gi"
  }
}

#################################################################################################  

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  create_namespace = true

  namespace = "argocd"
  values = [<<EOF
redis-ha:
  enabled: true

controller:
  replicas: 1

repoServer:
  autoscaling:
    enabled: true
    minReplicas: 2

applicationSet:
  replicas: 2

global:
  domain: "argocd.linasm.click"

configs:
  params:
    server.insecure: true

  cm:
    oidc.config: |
      name: AWS 
      issuer: "https://cognito-idp.eu-west-2.amazonaws.com/${var.cognito_user_pool_id}"
      clientID:  ${var.argocd_cognito_client_id}
      clientSecret: ${var.argocd_cognito_secret}  
      requestedScopes: ["openid", "profile", "email" ]
      requestedIDTokenClaims: {"groups": {"essential": true}}

server:
  replicas: 2

  ingress:
    enabled: true
    controller: aws
    ingressClassName: alb
    annotations:
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/backend-protocol: HTTP
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}, {"HTTPS":443}]'
      alb.ingress.kubernetes.io/ssl-redirect: '443'
      external-dns.alpha.kubernetes.io/hostname: argocd.linasm.click

    aws:
      serviceType: ClusterIP # <- Used with target-type: ip
      backendProtocolVersion: GRPC
EOF
  ]
}

#################################################################################################


resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"

  namespace        = "jenkins"
  create_namespace = true


  values = [<<EOF
persistence:
  storageClass: "gp2"
controller:
#  secretClaims:
#    - name: jenkins-secret
#      path: secret/path
#      renew: 60
  serviceAccount:
    create: true
    name: jenkins
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::975050322104:role/jenkins-ecr-role
  jenkinsUrlProtocol: https
  additionalPlugins:
    - oic-auth:latest
    - matrix-auth:latest
    - hashicorp-vault-plugin:latest
    - sonar:latest
  ingress:
    enabled: true
    apiVersion: networking.k8s.io/v1
    hostName: "jenkins.linasm.click"
    ingressClassName: alb
    annotations:
      kubernetes.io/ingress.class: alb
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}, {"HTTPS":443}]'
      alb.ingress.kubernetes.io/target-type: ip
      external-dns.alpha.kubernetes.io/hostname: jenkins.linasm.click
  JCasC:
    securityRealm: |
      oic:
        serverConfiguration:
          wellKnown:
            wellKnownOpenIDConfigurationUrl: "https://cognito-idp.eu-west-2.amazonaws.com/${var.cognito_user_pool_id}/.well-known/openid-configuration"
            scopesOverride: openid profile email
        clientId: ${var.jenkins_cognito_cliend_id}
        clientSecret: ${var.jenkins_cognito_secret}
        userNameField: "email"
        fullNameFieldName: "name"
        emailFieldName: "email"       
    authorizationStrategy: |
      globalMatrix:
        permissions:
          - "Overall/Administer:lincasm@gmail.com"
    hashicorpVault:
      configuration:
        vaultUrl: "http://vault.vault.svc:8200"
        engineVersion: 2
        kubernetesAuthRole: "jenkins"
    unclassified: |
      vault:
        enabled: true
        configuration:
          vaultUrl: "http://vault.vault.svc:8200"
          engineVersion: 2
          vaultAuth:
            kubernetesAuth:
              role: "jenkins"
              mountPath: "/var/run/secrets/kubernetes.io/serviceaccount/token"
          failIfNotFound: false
EOF
  ]
}




#################################################################################################

resource "helm_release" "aws-load-balancer" {
  name       = "aws-load-balancer"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  namespace        = "kube-system"
  create_namespace = true

  values = [
    yamlencode({
      clusterName = var.eks_cluster_name
      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
      }
      region = "eu-west-2"
      vpcId  = var.vpc_vpc_id
    })
  ]
}

#################################################################################################


resource "helm_release" "external-dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"

  namespace        = "kube-system"
  create_namespace = true

  values = [
    yamlencode({
      policy = "sync"
      provider = {
        name = "aws"
      }
      env = [
        {
          name  = "AWS_DEFAULT_REGION"
          value = "eu-west-2"
        }
      ]
      serviceAccount = {
        create = false
        name   = "external-dns"
        annotations = {
          "eks.amazonaws.com/role-arn" = "${var.AmazonEKSPodIdentityExternalDNSRole}:-kube-system"
        }
    } })

  ]
}


#################################################################################################

resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  repository = "jetstack"
  chart      = "cert-manager"

  namespace        = "cert-manager"
  create_namespace = true

  values = [
    yamlencode({
      installCRDs = true
    })
  ]
}

#################################################################################################

resource "helm_release" "vault" {
  name             = "vault"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault"
  namespace        = "vault"
  create_namespace = true

  values = [<<EOF
server:
  serviceAccount:
    create: true
    name: vault
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::975050322104:role/vault-irsa-unseal-role
  ha:
    enabled: true
    config: |
      cluster_name = "vault-integrated-storage"
      storage "dynamodb" {
        ha_enabled = "true"
        region     = "eu-west-2"
        table      = "vault-storage"
      }
      seal "awskms" {
        region     = "eu-west-2"
        kms_key_id = "arn:aws:kms:eu-west-2:975050322104:key/2d2687c3-c0fb-4561-b43f-79512a68742d"
        disable_aws_kms_tls_verification = true
      }
      listener "tcp" {
          address = "[::]:8200"
          cluster_address = "[::]:8201"
          tls_disable = "true"
      }
      service_registration "kubernetes" {}
EOF
  ]

  set {
    name  = "server.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.vault_unseal_role
  }
}


#      seal "awskms" {
#        region     = "eu-west-2"
#        kms_key_id = "alias/vault-unseal-key"
#        disable_aws_kms_tls_verification = true
#}