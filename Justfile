default:
    just -l

# Deploy a given service with Compose
[group("Docker")]
deploy SERVICE:
    #!/bin/bash
    if [ "{{SERVICE}}" = "kafka" ]; then
        docker compose -f docker/kafka/compose.yml up -d;
    else
        echo "Available options are: kafka" >&2
    fi
