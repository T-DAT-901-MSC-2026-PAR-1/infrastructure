terraform {

  # Temporarily using local backend for development
  # To switch back to Terraform Cloud, uncomment the remote backend below and comment out local backend
  # backend "remote" {
  #   organization = "glopez-personnal"
  #
  #   workspaces {
  #     name = "cryptoviz-kubernetes-cluster"
  #   }
  # }

  backend "local" {
  }

  required_version = ">= 1.6"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
