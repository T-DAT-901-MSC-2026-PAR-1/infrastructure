default:
    just -l

# Setup GCP project for Terraform deployment
[group("GCP")]
setup-gcp PROJECT_ID:
    #!/bin/bash
    ./scripts/setup-gcp-project.sh {{PROJECT_ID}}

# Deploy a given service with Compose or Terraform
[group("Docker Compose")]
up SERVICE:
    #!/bin/bash
    if [ "{{SERVICE}}" = "kafka" ]; then
        docker compose -f docker/kafka/compose.yml up -d;
    elif [ "{{SERVICE}}" = "terraform" ]; then
        docker compose -f docker/terraform/compose.yml up -d
    else
        echo "Available options are: kafka, terraform" >&2
    fi

[group("Docker Compose")]
down SERVICE:
    #!/bin/bash
    if [ "{{SERVICE}}" = "kafka" ]; then
        docker compose -f docker/kafka/compose.yml down;
    elif [ "{{SERVICE}}" = "terraform" ]; then
        docker compose -f docker/terraform/compose.yml down
    else
        echo "Available options are: kafka, terraform" >&2
    fi