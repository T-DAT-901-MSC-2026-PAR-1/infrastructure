# Terraform Updates: Static IP for Ingress Controller

## Overview
This document describes the updates made to the Terraform configuration to properly provision and configure a static IP address for the nginx-ingress controller LoadBalancer service.

## Problem Statement
The nginx-ingress controller was configured with a hardcoded static IP (`34.38.178.145`) in the Helm values, but this IP was never created in Google Cloud Platform (GCP). This caused the LoadBalancer service to remain in a `<pending>` state, preventing Let's Encrypt certificate validation and HTTPS access to ArgoCD.

## Solution
We've updated the Terraform configuration to:
1. **Create a static IP in GCP** during the GKE cluster setup
2. **Pass the IP dynamically** through Terraform to the Kubernetes cluster configuration
3. **Store the IP** for use by the nginx-ingress controller

## Changes Made

### 1. Google Kubernetes Engine Module (`terraform/modules/google_kubernetes_engine/`)

#### `main.tf`
Added a new resource to create a static external IP address:
```hcl
resource "google_compute_address" "ingress_ip" {
  name         = "${var.gke_cluster_name}-ingress-ip"
  address_type = "EXTERNAL"
  region       = substr(var.gke_zone, 0, length(var.gke_zone) - 2)
}
```

This:
- Creates a reserved static IP in GCP
- Automatically extracts the region from the zone (e.g., `europe-west1-b` → `europe-west1`)
- Names it based on the cluster name

#### `outputs.tf`
Added output to expose the created IP:
```hcl
output "ingress_ip_address" {
  description = "The static IP address for the ingress controller"
  value       = google_compute_address.ingress_ip.address
}
```

### 2. Kubernetes Cluster Module (`terraform/modules/kubernetes_cluster/`)

#### `variables.tf`
Added a new input variable:
```hcl
variable "ingress_ip_address" {
  description = "Static IP address for the ingress controller LoadBalancer"
  type        = string
}
```

#### `main.tf`
Added two resources:

**ConfigMap for infrastructure configuration:**
```hcl
resource "kubernetes_config_map" "infrastructure_config" {
  metadata {
    name      = "infrastructure-config"
    namespace = "default"
  }
  data = {
    ingress_ip_address = var.ingress_ip_address
  }
}
```

**ConfigMap patch for nginx-ingress values:**
```hcl
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
            type           = "LoadBalancer"
            loadBalancerIP = var.ingress_ip_address
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
```

This ConfigMap stores the correct loadBalancerIP value that should be used.

### 3. Kubernetes Cluster Root Module (`terraform/kubernetes_cluster/`)

#### `main.tf`
Updated the module call to pass the ingress IP:
```hcl
module "kubernetes_cluster" {
  source = "git::https://github.com/T-DAT-901-MSC-2026-PAR-1/infrastructure.git//terraform/modules/kubernetes_cluster?ref=main"

  gke_cluster_name      = data.terraform_remote_state.gke.outputs.cluster_name
  argocd_domain         = "argocd.cryptoviz.epitech-msc2026.me"
  argocd_admin_password = ""
  ingress_ip_address    = data.terraform_remote_state.gke.outputs.ingress_ip_address
}
```

### 4. Nginx-Ingress Values (`argocd/infrastructure/nginx-ingress/values.yaml`)

Updated the hardcoded IP to a placeholder that will be replaced:
```yaml
controller:
  service:
    type: LoadBalancer
    loadBalancerIP: "${ingress_ip_address}"  # Will be populated by Terraform ConfigMap
```

## Dependency Flow

```
terraform/google_kubernetes_engine/
  ├── Creates: google_compute_address.ingress_ip
  └── Outputs: ingress_ip_address
       └──↓
           terraform/kubernetes_cluster/main.tf
           └── Passes to: module.kubernetes_cluster
                └──↓
                    terraform/modules/kubernetes_cluster/main.tf
                    ├── Creates: infrastructure_config ConfigMap
                    └── Creates: nginx_values_patch ConfigMap
                         └──↓
                             Kubernetes Cluster
                             └── nginx-ingress reads the ConfigMap
```

## Execution Instructions (Docker)

Since you mentioned running Terraform in a Docker container, here's how to apply these changes:

### Prerequisites
- Docker running
- GCP credentials configured
- kubeconfig accessible to the container

### Step 1: Initialize GKE Infrastructure
```bash
# Navigate to the GKE configuration
cd terraform/google_kubernetes_engine

# Run Terraform init, plan, and apply in Docker
docker run -it --rm \
  -v "$(pwd):/workspace" \
  -v ~/.config/gcloud:/root/.gcloud:ro \
  -v ~/.kube:/root/.kube:ro \
  -e GOOGLE_APPLICATION_CREDENTIALS=/root/.gcloud/application_default_credentials.json \
  -w /workspace \
  hashicorp/terraform:latest \
  init

docker run -it --rm \
  -v "$(pwd):/workspace" \
  -v ~/.config/gcloud:/root/.gcloud:ro \
  -v ~/.kube:/root/.kube:ro \
  -e GOOGLE_APPLICATION_CREDENTIALS=/root/.gcloud/application_default_credentials.json \
  -w /workspace \
  hashicorp/terraform:latest \
  plan

docker run -it --rm \
  -v "$(pwd):/workspace" \
  -v ~/.config/gcloud:/root/.gcloud:ro \
  -v ~/.kube:/root/.kube:ro \
  -e GOOGLE_APPLICATION_CREDENTIALS=/root/.gcloud/application_default_credentials.json \
  -w /workspace \
  hashicorp/terraform:latest \
  apply
```

### Step 2: Initialize Kubernetes Cluster Infrastructure
```bash
# Navigate to the kubernetes cluster configuration
cd ../kubernetes_cluster

# Run Terraform init, plan, and apply
docker run -it --rm \
  -v "$(pwd):/workspace" \
  -v ~/.config/gcloud:/root/.gcloud:ro \
  -v ~/.kube:/root/.kube:ro \
  -e GOOGLE_APPLICATION_CREDENTIALS=/root/.gcloud/application_default_credentials.json \
  -w /workspace \
  hashicorp/terraform:latest \
  init

docker run -it --rm \
  -v "$(pwd):/workspace" \
  -v ~/.config/gcloud:/root/.gcloud:ro \
  -v ~/.kube:/root/.kube:ro \
  -e GOOGLE_APPLICATION_CREDENTIALS=/root/.gcloud/application_default_credentials.json \
  -w /workspace \
  hashicorp/terraform:latest \
  plan

docker run -it --rm \
  -v "$(pwd):/workspace" \
  -v ~/.config/gcloud:/root/.gcloud:ro \
  -v ~/.kube:/root/.kube:ro \
  -e GOOGLE_APPLICATION_CREDENTIALS=/root/.gcloud/application_default_credentials.json \
  -w /workspace \
  hashicorp/terraform:latest \
  apply
```

### Key Docker Flags Explanation:
- `-it`: Interactive terminal mode
- `--rm`: Remove container after execution
- `-v $(pwd):/workspace`: Mount current directory to /workspace in container
- `-v ~/.config/gcloud:/root/.gcloud:ro`: Mount GCP credentials (read-only)
- `-v ~/.kube:/root/.kube:ro`: Mount kubeconfig for Kubernetes access
- `-e GOOGLE_APPLICATION_CREDENTIALS=...`: Set GCP credentials path in container
- `-w /workspace`: Set working directory in container

## Verification Steps

After applying Terraform:

```bash
# 1. Verify static IP was created in GCP
gcloud compute addresses list --filter="name:*ingress*"

# 2. Check that LoadBalancer service has the IP assigned
kubectl get svc -n ingress-nginx
# Expected: nginx-ingress-ingress-nginx-controller with EXTERNAL-IP assigned

# 3. Verify ConfigMap was created
kubectl get configmap -n argocd
kubectl get configmap -n default infrastructure-config -o yaml

# 4. Check certificate status
kubectl get certificate -n argocd
# Expected: argocd-server-tls status should eventually show Ready=True

# 5. Once certificate is ready, verify ingress
kubectl get ingress -n argocd
```

## What to Do Next

1. **Update DNS**: Once the static IP is assigned, point your DNS record to this IP:
   ```bash
   # Get the assigned IP
   kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

   # Point argocd.cryptoviz.epitech-msc2026.me to this IP in your DNS provider
   ```

2. **Monitor Certificate**: Watch the certificate issuance progress:
   ```bash
   kubectl describe certificate argocd-server-tls -n argocd
   kubectl describe challenge -n argocd
   ```

3. **Access ArgoCD**: Once certificate is ready, access ArgoCD at:
   ```
   https://argocd.cryptoviz.epitech-msc2026.me
   ```

## Troubleshooting

If the LoadBalancer service is still pending after terraform apply:
```bash
# Check the service
kubectl describe svc -n ingress-nginx nginx-ingress-ingress-nginx-controller

# Check if IP is truly reserved
gcloud compute addresses describe cryptoviz-cluster-ingress-ip --region europe-west1
```

If nginx-ingress pods are not starting with the correct IP:
```bash
# Check the values being used
kubectl get helm -n ingress-nginx  # or equivalent command

# Check the ConfigMap values
kubectl get configmap -n argocd nginx-values-patch -o yaml
```

## Notes

- The static IP region is automatically extracted from the zone to ensure consistency with your GKE cluster location.
- The terraform state files should be properly backed up or stored in Terraform Cloud.
- When running in Docker, ensure all necessary environment variables are set before execution.
