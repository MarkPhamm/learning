# 1. Introduction

## 1.1 Container

What is a container? Simply put, containers are isolated processes for each of your app's components.

- **Self-contained.** Each container has everything it needs to function with no reliance on any pre-installed dependencies on the host machine.
- **Isolated.** Since containers are run in isolation, they have minimal influence on the host and other containers, increasing the security of your applications.
- **Independent.** Each container is independently managed. Deleting one container won't affect any others.
- **Portable.** Containers can run anywhere! The container that runs on your development machine will work the same way in a data center or anywhere in the cloud!

### Container vs VM

- VM is an entire operating system with its own kernel, hardware drivers, programs, and applications. Spinning up a VM only to isolate a single application is a lot of overhead.
- A container is simply an isolated process with all of the files it needs to run. If you run multiple containers, they all share the same kernel, allowing you to run more applications on less infrastructure.

| Feature | Container | VM |
|---|---|---|
| Startup time | Seconds | Minutes |
| Size | MBs (shares host kernel) | GBs (full OS) |
| Isolation | Process-level | Hardware-level |
| Performance | Near-native | Hypervisor overhead |
| Portability | Image runs anywhere Docker runs | Tied to hypervisor format |

```docker
docker ps        # List running containers
docker ps -a     # List all containers
docker stop      # Stop a running container
```

## 1.2 Image

A container image is a standardized package that includes all of the files, binaries, libraries, and configurations to run a container.

1. Images are immutable. Once an image is created, it can't be modified. You can only make a new image or add changes on top of it.
2. Container images are composed of layers. Each layer represents a set of file system changes that add, remove, or modify files.

### [Finding images](https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-an-image/#finding-images)

[Docker Hub](https://hub.docker.com/) is the default global marketplace for storing and distributing images.

- [Docker Official Images](https://hub.docker.com/search?q=&type=image&image_filter=official) - a curated set of Docker repositories, serve as the starting point for the majority of users, and are some of the most secure on Docker Hub
- [Docker Verified Publishers](https://hub.docker.com/search?q=&image_filter=store) - high-quality images from commercial publishers verified by Docker
- [Docker-Sponsored Open Source](https://hub.docker.com/search?q=&image_filter=open_source) - images published and maintained by open-source projects sponsored by Docker through Docker's open source program

```docker
docker image ls       # List all images
docker search         # Search for an image on Docker Hub
docker pull           # Download an image from a registry
docker image history  # Show the history of an image
```

## 1.3 Registry

An image registry is a centralized location for storing and sharing your container images. It can be either public or private. [Docker Hub](https://hub.docker.com/) is a public registry that anyone can use and is the default registry.

### Registry vs Repository

A *registry* is a centralized location that stores and manages container images, whereas a *repository* is a collection of related container images within a registry. Think of it as a folder where you organize your images based on projects. Each repository contains one or more container images.

| Concept | Analogy | Example |
|---|---|---|
| Registry | GitHub (the platform) | Docker Hub, ghcr.io, ECR |
| Repository | A GitHub repo | `library/nginx`, `myuser/myapp` |
| Tag | A git tag / branch | `latest`, `v1.2`, `alpine` |

## 1.4 What is `docker-compose`?

Docker Compose is basically a `yml` file for you to define configuration to run multiple container. You include this file in your code repository, anyone that clones your repository can get up and running with a single command.

You don't always need to recreate everything from scratch. If you make a change, run **`docker compose up`** again and Compose will reconcile the changes in your file and apply them intelligently.

### Basic structure of a `docker-compose.yaml`

```yaml
version: '3.8'

services:
  web:
    image: nginx:alpine          # Use an existing image
    ports:
      - "8080:80"                # Map host:container ports
    depends_on:
      - api                      # Start api before web

  api:
    build: ./api                 # Build from a Dockerfile
    environment:
      - DATABASE_URL=postgres://db:5432/myapp
    volumes:
      - ./api/src:/app/src       # Mount source code for live reload

  db:
    image: postgres:16
    volumes:
      - db_data:/var/lib/postgresql/data  # Named volume for persistence
    environment:
      - POSTGRES_PASSWORD=secret

volumes:
  db_data:                       # Declare named volumes
```

### Key Compose concepts

- **services** — each service becomes one or more containers
- **depends_on** — controls startup order (but doesn't wait for "ready", only "started")
- **volumes** — persist data beyond container lifecycle
- **networks** — Compose creates a default network so services can reach each other by name
- **env_file** — load environment variables from a file instead of inlining them

```docker
docker compose up -d --build
docker compose down
docker compose logs -f          # Follow logs from all services
docker compose exec web sh      # Shell into a running service
```
