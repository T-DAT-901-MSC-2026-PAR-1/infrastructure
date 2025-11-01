####################################################################################################
# Variables
####################################################################################################

variable "gke_cluster_name" {
  description = "GKE Cluster Name"
  default     = "cryptoviz-cluster"
  type        = string
}

variable "argocd_admin_password" {
  description = "Admin password for ArgoCD (if empty, a random one will be generated)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "argocd_domain" {
  description = "Domain for accessing ArgoCD"
  default     = "argocd.cryptoviz.epitech-msc2026.me"
  type        = string
}
