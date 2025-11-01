# Retrieve outputs from the GKE workspace
data "tfe_outputs" "cryptoviz_gke" {
  organization = "glopez-personnal"
  workspace    = "cryptoviz-google-kubernetes-engine"
}

# Retrieve a fresh authentication token as the one stored in the other workspace state file may be expired
data "google_client_config" "default" {}

module "kubernetes_cluster" {
  source = "git::https://github.com/T-DAT-901-MSC-2026-PAR-1/infrastructure.git//terraform/modules/kubernetes_cluster?ref=main"

  gke_cluster_name      = data.tfe_outputs.cryptoviz_gke.values.cluster_name
  argocd_domain         = "argocd.cryptoviz.epitech-msc2026.me"
  argocd_admin_password = "" # If empty, a random one will be generated
}