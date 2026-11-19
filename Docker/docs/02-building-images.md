# 2. Building Images

## 2.1 Understanding image layers

Each layer in an image contains a set of filesystem changes - additions, deletions, or modifications. Let's look at a theoretical image:

1. The first layer adds basic commands and a package manager, such as apt.
2. The second layer installs a Python runtime and pip for dependency management.
3. The third layer copies in an application's specific requirements.txt file.
4. The fourth layer installs that application's specific dependencies.
5. The fifth layer copies in the actual source code of the application.

### [Stacking the layers](https://docs.docker.com/get-started/docker-concepts/building-images/understanding-image-layers/#stacking-the-layers)

Layering is made possible by content-addressable storage and union filesystems. While this will get technical, here's how it works:

1. After each layer is downloaded, it is extracted into its own directory on the host filesystem.
2. When you run a container from an image, a union filesystem is created where layers are stacked on top of each other, creating a new and unified view.
3. When the container starts, its root directory is set to the location of this unified directory, using **`chroot`**.

You can inspect layers of any image:

```docker
docker image history nginx:alpine
```

## 2.2 Writing a `Dockerfile`

A `Dockerfile` is a text-based document that's used to create a container image. It provides instructions to the image builder on the commands to run, files to copy, startup command, and more.

```docker
FROM python:3.13
WORKDIR /usr/local/app

# Install the application dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy in the source code
COPY src ./src
EXPOSE 5000

# Setup an app user so the container doesn't run as the root user
RUN useradd app
USER app

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
```

### Dockerfile instructions reference

| Instruction | Purpose | Example |
|---|---|---|
| `FROM <image>` | Base image to build on | `FROM python:3.13-slim` |
| `WORKDIR <path>` | Set working directory inside the image | `WORKDIR /app` |
| `COPY <src> <dest>` | Copy files from host into the image | `COPY requirements.txt ./` |
| `ADD <src> <dest>` | Like COPY, but also handles URLs and tar extraction | `ADD app.tar.gz /app` |
| `RUN <command>` | Execute a command during build (creates a layer) | `RUN pip install -r requirements.txt` |
| `ENV <key> <value>` | Set an environment variable | `ENV NODE_ENV=production` |
| `ARG <key>` | Build-time variable (not available at runtime) | `ARG VERSION=1.0` |
| `EXPOSE <port>` | Document which port the container listens on | `EXPOSE 8080` |
| `USER <user>` | Set the user for subsequent instructions and runtime | `USER app` |
| `CMD ["cmd", "arg"]` | Default command when container starts | `CMD ["python", "main.py"]` |
| `ENTRYPOINT ["cmd"]` | Like CMD but harder to override — use for "executable" containers | `ENTRYPOINT ["python"]` |

### CMD vs ENTRYPOINT

- **CMD** sets the default command, but is completely replaced if you pass arguments to `docker run`.
- **ENTRYPOINT** defines the executable; arguments from `docker run` are appended to it.
- Combine them: `ENTRYPOINT` for the binary, `CMD` for default flags.

```docker
ENTRYPOINT ["python"]
CMD ["app.py"]

# docker run myimage           → runs: python app.py
# docker run myimage script.py → runs: python script.py
```

### .dockerignore

Like `.gitignore`, a `.dockerignore` file prevents unnecessary files from being sent to the build context. This speeds up builds and avoids leaking secrets.

```
.git
node_modules
__pycache__
*.pyc
.env
.DS_Store
```

## 2.3 Build, tag, and publish an image

### 2.3.1 Build

`docker build .` When you run a build, the builder pulls the base image, if needed, and then runs the instructions specified in the Dockerfile.

The final `.` in the command provides the path or URL to the [build context](https://docs.docker.com/build/concepts/context/#what-is-a-build-context). At this location, the builder will find the `Dockerfile` and other referenced files.

With the previous command, the image will have no name, but the output will provide the ID of the image.

```docker
docker build .
[+] Building 3.5s (11/11) FINISHED                                              docker:desktop-linux
 => [internal] load build definition from Dockerfile                                            0.0s
 => => transferring dockerfile: 308B                                                            0.0s
 => [internal] load metadata for docker.io/library/python:3.12                                  0.0s
 => [internal] load .dockerignore                                                               0.0s
 => => transferring context: 2B                                                                 0.0s
 => [1/6] FROM docker.io/library/python:3.12                                                    0.0s
 => [internal] load build context                                                               0.0s
 => => transferring context: 123B                                                               0.0s
 => [2/6] WORKDIR /usr/local/app                                                                0.0s
 => [3/6] RUN useradd app                                                                       0.1s
 => [4/6] COPY ./requirements.txt ./requirements.txt                                            0.0s
 => [5/6] RUN pip install --no-cache-dir --upgrade -r requirements.txt                          3.2s
 => [6/6] COPY ./app ./app                                                                      0.0s
 => exporting to image                                                                          0.1s
 => => exporting layers                                                                         0.1s
 => => writing image sha256:9924dfd9350407b3df01d1a0e1033b1e543523ce7d5d5e2c83a724480ebe8f00    0.0s
```

With the previous output, you could start a container by using the referenced image:

```docker
 docker run sha256:9924dfd9350407b3df01d1a0e1033b1e543523ce7d5d5e2c83a724480ebe8f00
```

That name certainly isn't memorable, which is where tagging becomes useful.

### 2.3.2 Tag

Tagging images is the method to provide an image with a memorable name. A full image name has the following structure:

```
[HOST[:PORT_NUMBER]/]PATH[:TAG]
```

- **`HOST`**: The optional registry hostname where the image is located. If no host is specified, Docker's public registry at **`docker.io`** is used by default.
- **`PORT_NUMBER`**: The registry port number if a hostname is provided
- **`PATH`**: The path of the image, consisting of slash-separated components. For Docker Hub, the format follows **`[NAMESPACE/]REPOSITORY`**, where namespace is either a user's or organization's name. If no namespace is specified, **`library`** is used, which is the namespace for Docker Official Images.
- **`TAG`**: A custom, human-readable identifier that's typically used to identify different versions or variants of an image. If no tag is specified, **`latest`** is used by default.

Examples:

- **`nginx`**, equivalent to **`docker.io/library/nginx:latest`**: this pulls an image from the **`docker.io`** registry, the **`library`** namespace, the **`nginx`** image repository, and the **`latest`** tag.
- **`docker/welcome-to-docker`**, equivalent to **`docker.io/docker/welcome-to-docker:latest`**: this pulls an image from the **`docker.io`** registry, the **`docker`** namespace, the **`welcome-to-docker`** image repository, and the **`latest`** tag
- **`ghcr.io/dockersamples/example-voting-app-vote:pr-311`**: this pulls an image from the GitHub Container Registry, the **`dockersamples`** namespace, the **`example-voting-app-vote`** image repository, and the **`pr-311`** tag

To tag an image during a build, add the **`-t`** or **`--tag`** flag:

```docker
docker build -t my-username/my-image .
```

If you've already built an image, you can add another tag to the image by using the [`docker image tag`](https://docs.docker.com/engine/reference/commandline/image_tag/) command:

```docker
docker image tag my-username/my-image another-username/another-image:v1
```

### 2.3.3 Publish

Once you have an image built and tagged, you're ready to push it to a registry. To do so, use the [`docker push`](https://docs.docker.com/engine/reference/commandline/image_push/) command:

```docker
docker push my-username/my-image
```

The full workflow looks like this:

```bash
# 1. Log in to Docker Hub
docker login

# 2. Build and tag
docker build -t myuser/myapp:v1 .

# 3. Push
docker push myuser/myapp:v1
```

## 2.4 Using the build cache

When building Docker images:

- Each instruction creates a layer that can be cached for future builds
- Cache invalidation happens when:
  - A `RUN` command changes
  - Files copied with `COPY`/`ADD` change
  - Any previous layer is invalidated

**Key insight:** Once a layer is invalidated, all subsequent layers must be rebuilt. That's why the order of instructions matters.

**Best practice:** For Node.js apps, structure your Dockerfile like this:

```docker
FROM node:22-alpine
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --production
COPY . .
CMD ["node", "src/index.js"]
```

This way, dependencies only reinstall when package.json changes, not when code changes.

The same principle applies to Python:

```docker
FROM python:3.13-slim
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["python", "main.py"]
```

## 2.5 Multi-stage builds

Multi-stage builds let you use multiple `FROM` statements in a single Dockerfile. Each `FROM` starts a new stage, and you can selectively copy artifacts from one stage to another. This keeps your final image small by excluding build tools and intermediate files.

```docker
# Stage 1: Build
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install
COPY . .
RUN yarn build

# Stage 2: Production
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

Why this matters:

- The `build` stage has Node.js, yarn, and all dev dependencies (~1 GB)
- The final image only has nginx + the built static files (~40 MB)
- Build tools never ship to production

Another common pattern — Go applications:

```docker
FROM golang:1.22 AS build
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /server

FROM scratch
COPY --from=build /server /server
EXPOSE 8080
CMD ["/server"]
```

The final image here is just the compiled binary — no OS, no shell, nothing else.
