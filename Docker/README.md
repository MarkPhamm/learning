# Docker

A hands-on repository documenting my journey learning Docker — from container basics to building and orchestrating real-world applications.

![image](https://github.com/user-attachments/assets/59c65354-b544-4189-9325-d636f2e29db1)

## TLDR

- **Container**: An isolated process that includes everything it needs to run, providing self-containment and portability.
- **Docker**: A platform that allows you to build, run, and manage containers.
- **Image**: A standardized package that contains all the files, dependencies, and configurations needed to run a container.
- **Registry**: A centralized storage location for container images, like Docker Hub.
- **`docker-compose`**: A tool for defining and running multi-container Docker applications using a YAML file.
- **`Dockerfile`**: A text document that contains instructions to build a Docker image.
- `docker build`: Build an image from `Dockerfile`

## Docs

- [Introduction](docs/01-introduction.md) — Core concepts: containers, images, registries, and docker-compose
- [Building Images](docs/02-building-images.md) — Dockerfile, image layers, build/tag/publish, caching, and multi-stage builds
- [Running Containers](docs/03-running-containers.md) — Ports, volumes, networking, environment variables, and lifecycle
- [Command Cheat Sheet](docs/04-commands.md) — Quick reference for all Docker CLI commands

## Project: Airflow with Docker Compose

This repo includes a working `docker-compose.yaml` that sets up Apache Airflow with:

- **PostgreSQL** — metadata database
- **Airflow Webserver** — UI on port 8080
- **Airflow Scheduler** — DAG execution

```bash
docker compose up -d --build
```
