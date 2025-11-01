terraform {

  # Temporarily using local backend for development
  # To switch back to Terraform Cloud, uncomment the remote backend below and comment out local backend
  # backend "remote" {
  #   organization = "glopez-personnal"
  #
  #   workspaces {
  #     name = "cryptoviz-google-kubernetes-engine"
  #   }
  # }

  backend "local" {
  }

  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
