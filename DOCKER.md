# Docker in this repo (from zero)

You do not need any Docker knowledge to use this project. This file is the whole map.

The short version: Docker is a way to run a tiny Linux computer on your Mac. That tiny computer already has Python and dbt installed. You type `dbt` **inside** it, not on your Mac.

---

## The four words

| Word | Everyday analogy | In this repo |
| --- | --- | --- |
| **Dockerfile** | A recipe | "Start from Python 3.12, install gcc/git, pip-install dbt" |
| **Image** | The finished cake sitting on the counter | A snapshot with Python + dbt already in it. Nothing is running yet |
| **Container** | Eating a slice of that cake | A running copy of the image. This is the Linux shell where you type `dbt debug` |
| **docker-compose.yaml** | A seating chart | Names the containers, says which folders from your Mac get plugged into them, and what command each one runs |

`docker-compose.yaml` is **not** a second kind of Docker. It is a config file that sits next to the Dockerfile and says "here is how to actually use that recipe."

Both services, and every volume mount, are defined in one place:

`docker-compose.yaml` at the repo root.

---

## The two services (the "doors")

This file defines **two** named ways to start the same image. They are called **services**.

```yaml
services:
    dbt-learn:     # interactive shell — you type dbt commands
    dbt-docs:      # website that stays up on localhost:8080
```

Same image. Different job. The line that decides **what you see when you `ls`** is the volume that ends in `:/app/`:

| Service | Volume line | What `/app` is |
| --- | --- | --- |
| `dbt-learn` (line 10) | `./dbt-learn/:/app/` | The dbt project folder (the "room") |
| `dbt-docs` (line 16) | `./dbt-learn:/app` | The same room, so `dbt docs serve` can find `dbt_project.yml` |

Whatever is on the **left** of the `:` gets mapped to `/app` **inside** the container. That left-hand path is what changes between services. In this repo both services point at the same folder, which is why they both look like a dbt project when you land in `/app`.

(If you also use `poc-dbt-practice`, that repo has a third service that mounts the **whole repo** as `/app`. This learn repo does not. Here `/app` is always the room, never the whole house.)

---

## How a volume line is read

Docker Compose volume lines follow one pattern:

```
<path on your computer>:<path inside the container>
```

Take the one you use every day:

```
./dbt-learn/:/app/
```

Split at the `:`:

- **Left** (`./dbt-learn/`) — a folder on your Mac, relative to where `docker-compose.yaml` sits.
  - `.` means "stay in this folder" (`poc-dbt-learn-on-demand/`)
  - then go into the `dbt-learn/` subfolder
- **Right** (`/app/`) — the path **inside the container** where that folder gets attached ("mounted")

Net effect: your real `dbt-learn/` folder **is** `/app` while the container is running. It is not a copy. Edit `models/dim_customers.sql` on your Mac, and the container sees it immediately.

The other mounts in this file work the same way:

| Line | Left (your Mac) | Right (inside the container) | Why |
| --- | --- | --- | --- |
| `$HOME/.aws:/root/.aws` | AWS folder in your home directory | `/root/.aws` | In case anything needs AWS creds |
| `./.dbt:/root/.dbt` | this repo's `.dbt/` | `/root/.dbt` | dbt looks here for `profiles.yml` |
| `./.ssh:/root/.ssh` | this repo's `.ssh/` | `/root/.ssh` | Snowflake key at `/root/.ssh/dbt_learn_key.p8` |
| `./dbt-learn/:/app/` | this repo's `dbt-learn/` | `/app` | the dbt project itself |

`$HOME` is your user home (`/Users/you`). `.` is "the folder that contains `docker-compose.yaml`".

---

## Why `pwd` is `/app` and `ls` shows `dbt_project.yml`

When you run:

```bash
docker compose run dbt-learn
```

you get something like:

```
root@c582f5056f73:/app#
```

Then `pwd` is `/app`, and `ls` shows `dbt_project.yml`, `models/`, `macros/`, …

Two things stack to make that happen:

1. **The Dockerfile** has `WORKDIR /app` at the bottom. That is baked into the image. It means: "before you run any command, `cd` into `/app`." That includes `command: /bin/bash`. So bash **always** starts in `/app`, no matter which service you run.
2. **The volume** for `dbt-learn` is `./dbt-learn/:/app/`. It takes your real `dbt-learn/` folder and makes it **be** `/app` inside the container.

Put together: the shell starts in `/app` (Dockerfile's doing), and `/app` happens to be your actual dbt project (the mount's doing). You are not in some extra "app dir" concept. You are standing in `dbt-learn/`, wearing a container name tag.

That is why you do **not** `cd dbt-learn` inside the container. You are already there.

The `/bin/bash` in compose is just "open a shell I can type into." It does not pick the directory. `WORKDIR` does.

---

## Why `build`, then `run` — not `up`

They do three different jobs. Mix them up and it feels like Docker is broken.

**`docker compose build`** — bake the image.

Reads the Dockerfile and does all the "install stuff" work (Python, dbt, apt packages). Saves the result as a reusable image. **Nothing runs yet.** Like following a recipe to bake a cake, then leaving it on the counter.

Do this:

- the first time
- whenever you change `Dockerfile` or `requirements.txt`

Do **not** do this just because you edited a SQL model. That file is mounted; the image does not need to change.

**`docker compose run dbt-learn`** — start a one-off container and attach your keyboard to it.

Uses the image from `build`. Applies the volume mounts. Runs `command: /bin/bash`. You get a prompt. When you type `exit`, it is done.

This is the daily command. It is like SSH-ing into that tiny Linux computer.

**`docker compose up dbt-docs`** — start a container as a standing thing, like a server.

`dbt-docs` has `entrypoint: dbt docs serve`. A website is meant to stay up and keep listening on port 8080. `up` is for that.

So the pattern in **this** repo:

```
build once (or when the recipe changes)
    → run dbt-learn     when you want a shell
    → up dbt-docs       when you want the docs website
```

If you ran `docker compose up dbt-learn` instead, you would start a container whose only job is `/bin/bash` with nobody typing into it. Bash needs a terminal attached. `run` gives you that. `up` does not, by default — so the container sits there or exits immediately.

`docker-compose` (hyphen) and `docker compose` (space) are the same tool for this repo. README uses the hyphen; newer Docker uses the space. Pick one.

---

## What you will see when you `run`

Typical output:

```
WARN  the attribute `version` is obsolete, it will be ignored
WARN  Found orphan containers (...-run-abc123, ...) for this project.
Container ... Creating
Container ... Created
root@<id>:/app#
```

**`version` is obsolete**  
The first line of `docker-compose.yaml` is `version: '3.3'`. New Compose ignores it. Harmless. You can delete that line later; nothing else changes.

**Orphan containers**  
Every `docker compose run` creates a **new** container. If you do not pass `--rm`, the old ones stick around after you `exit` (stopped, not running). Compose is telling you "I found leftovers from last time." Harmless. To avoid it:

```bash
docker compose run --rm dbt-learn
```

`--rm` means "throw this container away when I exit." The image stays. Your files on the Mac stay. Only the leftover shell-session container goes away.

To list leftovers: `docker ps -a`.

---

## Daily loop (copy-paste)

On your Mac, from `poc-dbt-learn-on-demand/` (the folder that contains `docker-compose.yaml`):

```bash
# First time, or after Dockerfile / requirements.txt changes
docker compose build

# Put the Snowflake key here once (do not commit it)
#   .ssh/dbt_learn_key.p8

# Open the shell
docker compose run --rm dbt-learn
```

Inside the container (`root@...:/app#`):

```bash
dbt debug
dbt run --vars '{target_prefix: YOUR_PREFIX}'
dbt docs generate
exit
```

Back on your Mac, serve the docs site:

```bash
docker compose up dbt-docs
```

Open `http://localhost:8080`. Stop with Ctrl+C.

---

## Picture of the whole flow

```
your Mac:  poc-dbt-learn-on-demand/
           ├── Dockerfile              recipe
           ├── docker-compose.yaml     seating chart
           ├── requirements.txt        pip packages (baked into the image)
           ├── .dbt/profiles.yml  ──►  mounted at /root/.dbt
           ├── .ssh/*.p8          ──►  mounted at /root/.ssh
           └── dbt-learn/         ──►  mounted at /app
                    models/
                    macros/
                    dbt_project.yml

docker compose build
        │
        ▼
     image   (Python 3.12 + dbt 1.12 already installed)

docker compose run dbt-learn
        │
        ▼
     container, bash starts in /app
        you type: dbt debug / dbt run / ...
        │
        ▼
     Snowflake  (profiles.yml + the .p8 key)
```

Two layers, on purpose:

- **Image** = tools (Python, dbt, gcc, vim). Rebuild when these change.
- **Volumes** = your files (models, profiles, key). Edit on the Mac; the container sees them. No rebuild.

---

## The Dockerfile, line by line

File: `Dockerfile`. This is the recipe. You only care about it when `build` is running.

```dockerfile
FROM python:3.12-slim-bookworm
```

Start from an official Python 3.12 Linux image (Debian Bookworm, slim = smaller). Every later line adds a layer on top.

```dockerfile
RUN apt-get update
RUN apt-get -y install gcc
```

Refresh Debian's package list, then install a C compiler. Some Python packages compile native code during `pip install`. `-y` = "yes" to prompts.

```dockerfile
RUN apt-get update -yqq \
  && apt-get install -yqq \
    postgresql \
    libssl-dev \
    less \
    vim \
    libffi-dev \
    libpq-dev \
    git
```

| Package | Why |
| --- | --- |
| `postgresql` | Leftover from an older stack. This project talks to Snowflake, not Postgres |
| `libssl-dev` / `libffi-dev` / `libpq-dev` | Headers used when compiling Python extensions |
| `git` | dbt uses git for packages |
| `vim` / `less` | Edit / page through files inside the container |

`-yqq` = yes, and quieter output.

```dockerfile
RUN pip install --upgrade pip
RUN echo 'alias ll="ls -lari"' >> ~/.bashrc
```

Newer pip, plus a convenience `ll` alias in bash.

```dockerfile
COPY requirements.txt .
RUN pip install -r requirements.txt
```

Copy **only** that one file in, then install `dbt-core==1.12.4` and `dbt-snowflake==1.12.0`.

Ordered on purpose: Docker caches layers. Changing a SQL model does **not** re-run pip. Changing `requirements.txt` does.

```dockerfile
RUN mkdir -p /app
COPY ./ /app/
RUN chmod 777 -R /app
WORKDIR /app
```

Create `/app`, copy the whole repo into the image (a fallback snapshot), make it writable, set `/app` as the default directory.

For `docker compose run`, that `COPY ./ /app/` is almost unused. Compose then **covers** `/app` with the live `./dbt-learn/` mount. You work on the Mac's files, not the snapshot from build time.

`WORKDIR /app` is the part you feel: it is why bash starts in `/app`.

---

## The compose file, line by line

File: `docker-compose.yaml`

```yaml
version: '3.3'
services:
```

`version` is ignored on new Docker (the warning you saw). `services` is the list of named containers.

Both services say `build: .` — "build from the Dockerfile in **this** folder." They share one image.

### `dbt-learn` — the shell you use daily

```yaml
    dbt-learn:
        build: .
        command: /bin/bash
        volumes:
            - $HOME/.aws:/root/.aws
            - ./.dbt:/root/.dbt
            - ./.ssh:/root/.ssh
            - ./dbt-learn/:/app/
```

| Key | Meaning |
| --- | --- |
| `build: .` | Use the Dockerfile here |
| `command: /bin/bash` | When the container starts, open a shell instead of running one command and quitting |
| last volume | the "door": `/app` **is** `dbt-learn/` |

### `dbt-docs` — the website

```yaml
    dbt-docs:
        build: .
        restart: always
        volumes:
          - ./.dbt:/root/.dbt
          - ./dbt-learn:/app
          - ./.ssh:/root/.ssh
        ports:
          - "8080:8080"
        entrypoint: dbt docs serve
```

Same image, same `/app` room, different process.

| Key | Meaning |
| --- | --- |
| `restart: always` | If it dies, start it again |
| `ports: "8080:8080"` | Mac port 8080 → container port 8080. Open `http://localhost:8080` |
| `entrypoint: dbt docs serve` | Always run the docs server (not bash) |

`command` vs `entrypoint`: both set "what process runs." Here `dbt-learn` uses `command: /bin/bash`. `dbt-docs` replaces the process with `dbt docs serve`.

You still have to `dbt docs generate` **inside** `dbt-learn` first. That writes files under `dbt-learn/target/`. Then `up dbt-docs` serves them. Generate = write the HTML. Serve = host it.

---

## How dbt finds Snowflake from inside Docker

dbt does not magically know Snowflake. Inside the container it reads:

1. `/app/dbt_project.yml` → `profile: 'profile_dbt_learn'`
2. `/root/.dbt/profiles.yml` → that profile, including `private_key_path: /root/.ssh/dbt_learn_key.p8`

Those paths only exist because compose mounts `./.dbt` and `./.ssh`. If `dbt debug` cannot find the profile or the key:

- you are not in a compose `run` (wrong folder on the Mac, or a raw `docker run` with no volumes)
- `.ssh/dbt_learn_key.p8` is missing on the Mac
- `.dbt/profiles.yml` is missing on the Mac

The image does **not** contain your key. Gitignore keeps `.ssh/*` out of git.

---

## Rebuild or not

| You changed | Rebuild? | Why |
| --- | --- | --- |
| `Dockerfile` | Yes | Recipe changed |
| `requirements.txt` | Yes | `pip install` happens at build time |
| SQL models, macros, `dbt_project.yml` | No | Mounted from `./dbt-learn` |
| `.dbt/profiles.yml` | No | Mounted |
| `.ssh/dbt_learn_key.p8` | No | Mounted |

After a rebuild, start a **new** `docker compose run`. An already-open container still has the old image.

---

## Other commands, when you need them

All of these are typed **on the Mac**, from the repo root.

```bash
docker compose ps              # what is running right now
docker compose logs dbt-docs   # docs-server output
docker compose down            # stop things started with `up` (not your image)
docker images                  # images on this machine
docker ps -a                   # all containers, including leftover `run` ones
```

`docker compose exec` runs a command in a container that is **already** running. This repo's usual flow is `run` (a new container each time), so you will almost never need `exec`.

One-shot without opening bash:

```bash
docker compose run --rm dbt-learn dbt debug
```

Same mounts, runs `dbt debug` instead of bash, prints the result, exits.

---

## If something feels wrong

**`dbt: command not found` on the Mac**  
You are not inside the container. `docker compose run --rm dbt-learn` first. The prompt should look like `root@...:/app#`.

**I edited SQL and the container does not see it**  
You need the compose volume `./dbt-learn/:/app/`. If you used a raw `docker run` without that mount, you are looking at the snapshot from `COPY ./ /app/` at build time.

**I changed `requirements.txt` but `dbt --version` is still old**  
Rebuild, then a **new** container:

```bash
docker compose build
docker compose run --rm dbt-learn
```

**Port 8080 already in use**  
An old `dbt-docs` (or something else) holds the port. `docker compose down`, or change the left-hand port to `"8081:8080"` and open `http://localhost:8081`.

**Debian apt 404 / old Buster image**  
Older Dockerfiles used `python:3.8.7-slim-buster`. Current file uses `python:3.12-slim-bookworm`. See `issues.md`. Rebuild from the current Dockerfile.
