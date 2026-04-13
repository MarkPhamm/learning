# 3. Running Containers

## 3.1 Publishing and exposing ports

Port publishing exposes container services by mapping host:container ports. Use **`-p`** flag with **`docker run`** to create forwarding rules (e.g., **`-p 8080:80`** routes host:8080 → container:80).

```docker
docker run -d -p HOST_PORT:CONTAINER_PORT nginx
```

- **`HOST_PORT`**: The port number on your host machine where you want to receive traffic
- **`CONTAINER_PORT`**: The port number within the container that's listening for connections

For example, to publish the container's port **`80`** to host port **`8080`**:

```docker
docker run -d -p 8080:80 nginx
```

Now, any traffic sent to port **`8080`** on your host machine will be forwarded to port **`80`** within the container.

You can also map multiple ports:

```docker
docker run -d -p 8080:80 -p 8443:443 nginx
```

Or let Docker pick a random host port:

```docker
docker run -d -p 80 nginx    # Docker assigns a random host port
docker port <container>       # See what port was assigned
```

## 3.2 Overriding the default command

`CMD` in a Dockerfile sets the default, but you can override it at runtime:

```docker
# Default: runs the CMD from the image
docker run python:3.13

# Override: run a specific script instead
docker run python:3.13 python my_script.py

# Interactive shell inside the container
docker run -it python:3.13 bash
```

## 3.3 Environment variables

Pass configuration into containers without rebuilding the image:

```docker
# Single variable
docker run -e DATABASE_URL=postgres://localhost/mydb myapp

# From a file
docker run --env-file .env myapp
```

Inside the container, these are available as regular environment variables. This is how most Docker images are configured (database credentials, feature flags, API keys, etc).

## 3.4 Volumes and bind mounts

Data inside a container is lost when the container is removed. Volumes and bind mounts solve this.

### Bind mounts — map a host directory into the container

```docker
# Mount current directory into /app in the container
docker run -v $(pwd):/app myimage

# Read-only mount
docker run -v $(pwd)/config:/app/config:ro myimage
```

Bind mounts are useful for development — edit files on your host and see changes reflected inside the container immediately.

### Named volumes — Docker-managed persistent storage

```docker
# Create and use a named volume
docker run -v mydata:/var/lib/postgresql/data postgres

# List volumes
docker volume ls

# Inspect a volume
docker volume inspect mydata

# Remove unused volumes
docker volume prune
```

Named volumes are the preferred way to persist data in production. Docker manages the storage location, and data survives container removal.

| Feature | Bind mount | Named volume |
|---|---|---|
| Source | Host filesystem path | Docker-managed |
| Use case | Development, config files | Database storage, persistent data |
| Portability | Tied to host paths | Works anywhere Docker runs |
| Performance on macOS | Slower (filesystem translation) | Faster (native Docker storage) |

## 3.5 Container lifecycle

A container goes through these states:

```
Created → Running → Paused → Stopped → Removed
```

Common lifecycle commands:

```docker
docker create nginx            # Create but don't start
docker start <container>       # Start a created/stopped container
docker pause <container>       # Freeze a running container
docker unpause <container>     # Resume a paused container
docker stop <container>        # Graceful stop (SIGTERM, then SIGKILL after 10s)
docker kill <container>        # Immediate stop (SIGKILL)
docker rm <container>          # Remove a stopped container
docker rm -f <container>       # Force remove (stop + remove)
```

Run and auto-remove when done:

```docker
docker run --rm alpine echo "hello"   # Container is removed after it exits
```

## 3.6 Container networking

By default, Docker creates a bridge network. Containers on the same network can talk to each other by container name.

```docker
# Create a custom network
docker network create mynet

# Run containers on the same network
docker run -d --name db --network mynet postgres
docker run -d --name app --network mynet myapp

# Inside "app", you can reach postgres at hostname "db"
# e.g. postgres://db:5432/mydb
```

Network types:

| Driver | Description |
|---|---|
| `bridge` | Default. Isolated network on a single host. |
| `host` | Container shares the host's network stack (no isolation). |
| `none` | No networking. Container is completely isolated. |
| `overlay` | Spans multiple Docker hosts (used with Docker Swarm). |

## 3.7 Resource limits

Prevent containers from consuming all host resources:

```docker
# Limit memory to 512MB
docker run -m 512m myapp

# Limit to 1.5 CPUs
docker run --cpus 1.5 myapp

# Both
docker run -m 512m --cpus 1.5 myapp
```

## 3.8 Viewing logs

```docker
docker logs <container>          # All logs
docker logs -f <container>       # Follow (stream) logs
docker logs --tail 100 <container>  # Last 100 lines
docker logs --since 1h <container>  # Logs from the last hour
```
