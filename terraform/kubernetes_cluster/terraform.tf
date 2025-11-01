terraform {

  # Use Terraform Cloud as the backend to store the state file
  backend "remote" {
    organization = "glopez-personnal"

    workspaces {
      name = "cryptoviz-kubernetes-cluster"
    }
  }

  required_version = ">= 1.6"
}
