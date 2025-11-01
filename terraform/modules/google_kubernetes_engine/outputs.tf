#####################################################################################################
# Outputs
#####################################################################################################

output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.cryptoviz.name
}

output "cluster_endpoint" {
  description = "The endpoint to access the GKE cluster"
  value       = google_container_cluster.cryptoviz.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The CA certificate for the GKE cluster"
  value       = google_container_cluster.cryptoviz.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

