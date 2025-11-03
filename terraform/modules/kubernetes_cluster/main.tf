####################################################################################################
# Generate a random password if not provided
####################################################################################################
resource "random_password" "argocd_admin" {
  count   = var.argocd_admin_password == "" ? 1 : 0
  length  = 16
  special = true
}

locals {
  argocd_admin_password = var.argocd_admin_password != "" ? var.argocd_admin_password : random_password.argocd_admin[0].result
}

####################################################################################################
# Create a ConfigMap to store infrastructure configuration
####################################################################################################
resource "kubernetes_config_map" "infrastructure_config" {
  metadata {
    name      = "infrastructure-config"
    namespace = "default"
  }

  data = {
    ingress_ip_address = var.ingress_ip_address
  }
}

####################################################################################################
# Create the namespace for ArgoCD
####################################################################################################

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      name = "argocd"
    }
  }
}

####################################################################################################
# Deploy ArgoCD using Helm
####################################################################################################

resource "helm_release" "argocd" {
  depends_on = [kubernetes_namespace.argocd, kubernetes_config_map.infrastructure_config]

  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "8.5.2" # Stable version at the time of writing
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  timeout = 600

  # Custom values for ArgoCD
  values = [
    templatefile("${path.module}/values.yaml", {
      domain              = var.argocd_domain
      admin_password_hash = bcrypt(local.argocd_admin_password)
    })
  ]

  # Wait for the nodes to be ready
  wait          = true
  wait_for_jobs = true
}

####################################################################################################
# Create a script to update nginx-ingress values with the dynamic IP
####################################################################################################
resource "kubernetes_manifest" "nginx_values_patch" {
  manifest = {
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "nginx-values-patch"
      namespace = "argocd"
    }
    data = {
      "nginx-values.yaml" = yamlencode({
        controller = {
          service = {
            type             = "LoadBalancer"
            loadBalancerIP   = var.ingress_ip_address
            annotations = {
              "cloud.google.com/load-balancer-type" = "External"
            }
          }
        }
      })
    }
  }

  depends_on = [helm_release.argocd]
}



