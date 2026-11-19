# Docker Command Cheat Sheet

## Images

| Command | Description |
|---|---|
| `docker pull <image>` | Download an image from Docker Hub |
| `docker images` / `docker image ls` | List images available locally |
| `docker rmi <image>` | Remove an image |
| `docker build -t <name>:<tag> .` | Build an image from a Dockerfile |
| `docker search <term>` | Search for an image on Docker Hub |
| `docker image history <image>` | Show the history / layers of an image |
| `docker image inspect <image>` | Show detailed metadata about an image |

## Containers

| Command | Description |
|---|---|
| `docker run <image>` | Create and start a container |
| `docker run -it <image> bash` | Run interactively with a shell |
| `docker run -d <image>` | Run in detached (background) mode |
| `docker run --name myapp <image>` | Assign a name to the container |
| `docker run -p 8080:80 <image>` | Map host port 8080 to container port 80 |
| `docker run -v ./data:/app/data <image>` | Bind mount a host directory |
| `docker run -e KEY=value <image>` | Set an environment variable |
| `docker run --rm <image>` | Auto-remove container when it exits |
| `docker ps` | List running containers |
| `docker ps -a` | List all containers (including stopped) |
| `docker stop <container>` | Stop a running container |
| `docker start <container>` | Start a stopped container |
| `docker restart <container>` | Restart a container |
| `docker rm <container>` | Remove a stopped container |
| `docker rm -f <container>` | Force remove (stop + remove) |

## Inspect & Debug

| Command | Description |
|---|---|
| `docker inspect <container>` | Show detailed info (JSON) about a container |
| `docker logs <container>` | Show container logs |
| `docker logs -f <container>` | Follow / stream logs |
| `docker logs --tail 50 <container>` | Show last 50 lines of logs |
| `docker exec -it <container> bash` | Open a shell inside a running container |
| `docker exec <container> <cmd>` | Run a one-off command in a container |
| `docker top <container>` | Show running processes in a container |
| `docker stats` | Live resource usage for all containers |
| `docker diff <container>` | Show filesystem changes in a container |

## Docker Compose

| Command | Description |
|---|---|
| `docker compose up` | Start all services |
| `docker compose up -d` | Start in detached mode |
| `docker compose up -d --build` | Rebuild images before starting |
| `docker compose up --force-recreate` | Recreate containers even if unchanged |
| `docker compose up --remove-orphans` | Remove containers for undefined services |
| `docker compose -f custom.yml up` | Use a specific Compose file |
| `docker compose down` | Stop and remove services |
| `docker compose down -v` | Also remove named volumes |
| `docker compose ps` | List services and their status |
| `docker compose logs` | Show logs for all services |
| `docker compose logs -f <service>` | Follow logs for a specific service |
| `docker compose exec <service> bash` | Shell into a running service |
| `docker compose build` | Build or rebuild images |
| `docker compose pull` | Pull latest images for services |
| `docker compose restart <service>` | Restart a specific service |

## Volumes

| Command | Description |
|---|---|
| `docker volume ls` | List all volumes |
| `docker volume create <name>` | Create a named volume |
| `docker volume inspect <name>` | Show volume details |
| `docker volume rm <name>` | Remove a volume |
| `docker volume prune` | Remove all unused volumes |

## Networks

| Command | Description |
|---|---|
| `docker network ls` | List networks |
| `docker network create <name>` | Create a network |
| `docker network connect <net> <container>` | Connect a container to a network |
| `docker network disconnect <net> <container>` | Disconnect a container from a network |
| `docker network inspect <name>` | Show network details |
| `docker network rm <name>` | Remove a network |

## Cleanup

| Command | Description |
|---|---|
| `docker system prune` | Remove all unused containers, networks, and images |
| `docker system prune -a` | Also remove unused images (not just dangling) |
| `docker system prune --volumes` | Also remove unused volumes |
| `docker image prune` | Remove dangling images |
| `docker container prune` | Remove stopped containers |
| `docker system df` | Show Docker disk usage |
