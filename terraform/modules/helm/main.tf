
provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }

}
resource "helm_release" "karpenter" {
#  depends_on = [var.eks]
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.5.0"

  namespace = "kube-system"


  set = [
    {
      name  = "settings.clusterName"
      value = var.eks_cluster_name
    },
    {
      name  = "controller.resources.requests.cpu"
      value = "1"
    },
    {
      name  = "controller.resources.requests.memory"
      value = "1Gi"
    },
    {
      name  = "controller.resources.limits.cpu"
      value = "1"
    },
    {
      name  = "controller.resources.limits.memory"
      value = "1Gi"
    }
  ]
}
  
