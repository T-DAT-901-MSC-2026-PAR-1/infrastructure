#!/usr/bin/env bash
set -euo pipefail

# Simple script to generate a self-signed CA and per-broker keystores/truststores
# and a client keystore/truststore for testing.
# Generated files are placed under each node directory: node-1/certs, node-2/certs, node-3/certs
# Usage: run from this directory (docker/kafka): ./script/generate-certs.sh

PWD_DIR=$(cd "$(dirname "$0")/.." && pwd)
OUT_DIR="$PWD_DIR"

PASSWORD=${PASSWORD:-superSecretPassword}
DAYS=${DAYS:-365}

CA_DIR="$OUT_DIR/ca"
mkdir -p "$CA_DIR"
CA_KEY="$CA_DIR/ca.key.pem"
CA_CERT="$CA_DIR/ca.crt.pem"

echo "Using passwords: keystore/key/truststore = $PASSWORD"

if [[ -f "$CA_KEY" ]]; then
  echo "CA already exists at $CA_KEY, reusing"
else
  echo "Generating CA key and cert..."
  openssl req -new -x509 -keyout "$CA_KEY" -out "$CA_CERT" -days $DAYS -nodes -subj "/CN=Kafka-Local-CA"
fi

for NODE in node-1 node-2 node-3; do
  echo "\nProcessing $NODE"
  NODE_DIR="$OUT_DIR/$NODE/certs"
  mkdir -p "$NODE_DIR"
  # If keystore already exists, skip generation to avoid duplicate-alias errors
  if [[ -f "$NODE_DIR/kafka.server.keystore.jks" ]]; then
    echo "Keystore already exists for $NODE, skipping generation (remove $NODE_DIR/kafka.server.keystore.jks to regenerate)"
  else
    # Create a keystore with a keypair
    keytool -keystore "$NODE_DIR/kafka.server.keystore.jks" -alias kafka -validity $DAYS -genkey -keyalg RSA \
      -storepass "$PASSWORD" -keypass "$PASSWORD" -dname "CN=$NODE,OU=Kafka,O=Local,L=City,ST=State,C=FR"

    # Create CSR
    keytool -keystore "$NODE_DIR/kafka.server.keystore.jks" -alias kafka -certreq -file "$NODE_DIR/$NODE.csr" \
      -storepass "$PASSWORD"

    # Sign CSR with CA
    openssl x509 -req -CA "$CA_CERT" -CAkey "$CA_KEY" -in "$NODE_DIR/$NODE.csr" -out "$NODE_DIR/$NODE.crt" -days $DAYS -CAcreateserial -sha256

    # Import CA into keystore as root
    keytool -keystore "$NODE_DIR/kafka.server.keystore.jks" -alias CARoot -import -file "$CA_CERT" -storepass "$PASSWORD" -noprompt

    # Import signed cert into keystore
    keytool -keystore "$NODE_DIR/kafka.server.keystore.jks" -alias kafka -import -file "$NODE_DIR/$NODE.crt" -storepass "$PASSWORD" -noprompt

    # Create truststore (contains CA) for server
    keytool -keystore "$NODE_DIR/kafka.server.truststore.jks" -alias CARoot -import -file "$CA_CERT" -storepass "$PASSWORD" -noprompt

    echo "Created keystore and truststore for $NODE in $NODE_DIR"
  fi
done

# Create a client keystore and truststore
CLIENT_DIR="$OUT_DIR/client"
mkdir -p "$CLIENT_DIR"

keytool -keystore "$CLIENT_DIR/kafka.client.keystore.jks" -alias client -validity $DAYS -genkey -keyalg RSA \
  -storepass "$PASSWORD" -keypass "$PASSWORD" -dname "CN=kafka-client,OU=Kafka,O=Local,L=City,ST=State,C=FR"

keytool -keystore "$CLIENT_DIR/kafka.client.keystore.jks" -alias client -certreq -file "$CLIENT_DIR/client.csr" -storepass "$PASSWORD"
openssl x509 -req -CA "$CA_CERT" -CAkey "$CA_KEY" -in "$CLIENT_DIR/client.csr" -out "$CLIENT_DIR/client.crt" -days $DAYS -CAcreateserial -sha256
keytool -keystore "$CLIENT_DIR/kafka.client.keystore.jks" -alias CARoot -import -file "$CA_CERT" -storepass "$PASSWORD" -noprompt
keytool -keystore "$CLIENT_DIR/kafka.client.keystore.jks" -alias client -import -file "$CLIENT_DIR/client.crt" -storepass "$PASSWORD" -noprompt

# Client truststore (trusts CA)
keytool -keystore "$CLIENT_DIR/kafka.client.truststore.jks" -alias CARoot -import -file "$CA_CERT" -storepass "$PASSWORD" -noprompt

echo "\nClient keystore and truststore created in $CLIENT_DIR"

echo "\nDone. To use SSL for clients: start the brokers (docker compose up) then configure clients to use:\n  ssl.keystore.location=/path/to/kafka.client.keystore.jks\n  ssl.keystore.password=$PASSWORD\n  ssl.key.password=$PASSWORD\n  ssl.truststore.location=/path/to/kafka.client.truststore.jks\n  ssl.truststore.password=$PASSWORD\n"

exit 0
