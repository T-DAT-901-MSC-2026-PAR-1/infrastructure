# Retrieve outputs from the local GKE terraform state
data "terraform_remote_state" "gke" {
  backend = "local"

  config = {
    path = "../google_kubernetes_engine/terraform.tfstate"
  }
}

# Retrieve a fresh authentication token as the one stored in the other workspace state file may be expired
data "google_client_config" "default" {}

module "kubernetes_cluster" {
  source = "git::https://github.com/T-DAT-901-MSC-2026-PAR-1/infrastructure.git//terraform/modules/kubernetes_cluster?ref=main"

  gke_cluster_name      = data.terraform_remote_state.gke.outputs.cluster_name
  argocd_domain         = "argocd.cryptoviz.epitech-msc2026.me"
  argocd_admin_password = "" # If empty, a random one will be generated
  ingress_ip_address    = data.terraform_remote_state.gke.outputs.ingress_ip_address
}
