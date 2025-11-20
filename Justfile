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
    elif [ "{{SERVICE}}" = "certs" ]; then
        # Run the cert generation compose which writes certs to the repo via a mounted volume
        docker compose -f docker/certs/compose.yml up --no-recreate
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
    elif [ "{{SERVICE}}" = "certs" ]; then
        docker compose -f docker/certs/compose.yml down
    elif [ "{{SERVICE}}" = "terraform" ]; then
        docker compose -f docker/terraform/compose.yml down
    else
        echo "Available options are: kafka, terraform" >&2
    fi

[group("Docker Compose")]
logs SERVICE:
    #!/bin/bash
    if [ "{{SERVICE}}" = "kafka" ]; then
        docker compose -f docker/kafka/compose.yml logs;
    elif [ "{{SERVICE}}" = "certs" ]; then
        docker compose -f docker/certs/compose.yml logs
    elif [ "{{SERVICE}}" = "terraform" ]; then
        docker compose -f docker/terraform/compose.yml logs 
    else
        echo "Available options are: kafka, terraform" >&2
    fi

[group("Docker Compose")]
generate-certs:
    bash ./docker/kafka/script/generate-certs.sh
