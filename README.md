# Infrastructure

This repository stores all the infrastructure configurations for the Crypto Viz project.

## What is Just?
[Just](https://github.com/casey/just) is a command runner similar to Make, but simpler and more modern. It lets you define recipes in a `Justfile` and run them easily.

## What is Kafka?
[Apache Kafka](https://kafka.apache.org/) is a distributed event streaming platform used for building real-time data pipelines and streaming applications. It is highly scalable and fault-tolerant.

## How to Install Just

On Linux, you can install Just using Python and pipx:

```sh
python3 -m pip install --user pipx
python3 -m pipx ensurepath
pipx install just
```

For other platforms and installation methods, see the [Just installation guide](https://github.com/casey/just#installation).

## How to Deploy Docker Compose Files

1. Make sure Docker is installed and running.
2. Install Just (see above).
3. Run the following command from the project root:

```sh
just # Displays the available recipes
```

For example, to deploy Kafka:

```sh
just deploy kafka # Deploys kafka with Docker Compose
```