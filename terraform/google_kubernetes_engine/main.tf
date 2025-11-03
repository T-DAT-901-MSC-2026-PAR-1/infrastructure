####################################################################################################
# DATA SOURCES
####################################################################################################
# Retrieve a fresh authentication token
data "google_client_config" "default" {}

####################################################################################################
# GKE CLUSTER MODULE
####################################################################################################
module "google_kubernetes_engine" {
  source = "../modules/google_kubernetes_engine"

  gcp_project_id   = var.gcp_project_id
  gke_cluster_name = var.gke_cluster_name
  gke_zone         = var.gke_zone
}

####################################################################################################
# KUBERNETES PROVIDER - For managing cluster resources
####################################################################################################
provider "kubernetes" {
  host                   = "https://${module.google_kubernetes_engine.cluster_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.google_kubernetes_engine.cluster_ca_certificate)
}

####################################################################################################
# RBAC: Grant terraform service account cluster-admin role
####################################################################################################
resource "kubernetes_cluster_role_binding" "terraform_admin" {
  metadata {
    name = "terraform-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind = "User"
    name = "terraform-service-account@glowing-palace-476917-e5.iam.gserviceaccount.com"
  }
}
