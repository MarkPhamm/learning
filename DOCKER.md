# Docker in this repo (from zero)

You do not need any Docker knowledge to use this project. This file is the whole map.

The short version: Docker is a way to run a tiny Linux computer on your Mac. That tiny computer already has Python and dbt installed. You type `dbt` **inside** it, not on your Mac.

---

## The four words

| Word | Everyday analogy | In this repo |
| --- | --- | --- |
| **Dockerfile** | A recipe | "Start from Python 3.12, install git and gcc, pip-install dbt" |
| **Image** | The finished cake sitting on the counter | A snapshot with Python + dbt already in it. Nothing is running yet |
| **Container** | Eating a slice of that cake | A running copy of the image. This is the Linux shell where you type `dbt build` |
| **docker-compose.yaml** | A seating chart | Names the containers, says which folders from your Mac get plugged into them, and what command each one runs |

`docker-compose.yaml` is **not** a second kind of Docker. It is a config file that sits next to the Dockerfile and says "here is how to actually use that recipe."

Every service and every volume mount is defined in one place: `docker-compose.yaml` at the repo root.

---

## The three services (the "doors")

This file defines **three** named ways to start the same image. They are called **services**.

```yaml
services:
  dbt_base:       # shell at the repo root, for poking around
  dbt_snowflake:  # the Snowflake dbt project
  dbt_duckdb:     # the DuckDB dbt project
```

Same image, three jobs. The line that decides **what you see when you `ls`** is the volume that ends in `:/app`:

| Service | Volume line | What `/app` is |
| --- | --- | --- |
| `dbt_base` | `./:/app` | The whole repo |
| `dbt_snowflake` | `./dbt-snowflake:/app` | The Snowflake dbt project |
| `dbt_duckdb` | `./dbt-duckdb:/app` | The DuckDB dbt project |

Whatever is on the **left** of the `:` gets mapped to `/app` **inside** the container.

### Why two dbt projects and not one

This is the part people get wrong. Snowflake and DuckDB do not speak the same SQL, so the **model code** has to diverge. That is a code boundary, not a container boundary.

The image is byte-identical for both services. `requirements.txt` installs `dbt-snowflake` and `dbt-duckdb` side by side, so every container has both adapters. What actually differs is which project folder lands on `/app` and which target dbt connects with. The services exist to encode those two arguments so you never have to type them.

---

## How a volume line is read

Docker Compose volume lines follow one pattern:

```
<path on your computer>:<path inside the container>
```

Take the one the DuckDB service uses:

```
./dbt-duckdb:/app
```

Split at the `:`:

- **Left** (`./dbt-duckdb`) — a folder on your Mac, relative to where `docker-compose.yaml` sits. `.` means "stay in this folder," then go into the `dbt-duckdb/` subfolder.
- **Right** (`/app`) — the path **inside the container** where that folder gets attached ("mounted")

Net effect: your real `dbt-duckdb/` folder **is** `/app` while the container runs. It is not a copy. Edit `models/marts/marketing/dim_customers.sql` on your Mac and the container sees it immediately.

The full set of mounts:

| Line | Left (your Mac) | Right (in container) | Why |
| --- | --- | --- | --- |
| `./.dbt:/root/.dbt` | this repo's `.dbt/` | `/root/.dbt` | dbt looks here for `profiles.yml` |
| `./.ssh:/root/.ssh` | this repo's `.ssh/` | `/root/.ssh` | Snowflake key at `/root/.ssh/snowflake_key.p8` |
| `./dbt-duckdb:/app` | the DuckDB project | `/app` | the dbt project itself |
| `./utils/duckdb:/utils` | the DuckDB setup scripts | `/utils` | `load_raw.py` builds the source data |

The last one only exists on `dbt_duckdb`. The Snowflake service has no `/utils` mount, because nothing in `utils/snowflake/` runs in a container: both SQL files execute in a Snowflake worksheet, and `generate_key.sh` runs on your Mac.

---

## Why `pwd` is `/app`

When you run:

```bash
docker compose run --rm dbt_duckdb bash
```

you land at `root@<id>:/app#`, and `ls` shows `dbt_project.yml`, `models/`, `macros/`.

Two things stack to make that happen:

1. **The Dockerfile** ends with `WORKDIR /app`. That is baked into the image: before running any command, `cd` into `/app`. So bash always starts there, whichever service you pick.
2. **The volume** `./dbt-duckdb:/app` makes your real project folder **be** `/app`.

You are standing in `dbt-duckdb/`, wearing a container name tag. That is why you never `cd` anywhere after landing.

---

## How the target gets picked

Each service sets an environment variable:

```yaml
  dbt_duckdb:
    environment:
      DBT_TARGET: dbt_duckdb_dev
```

And `.dbt/profiles.yml` reads it:

```yaml
profiles_dbt_docker:
  target: "{{ env_var('DBT_TARGET', 'dbt_duckdb_dev') }}"
```

dbt renders `profiles.yml` through Jinja before parsing it, so `env_var` works there. The result is that a bare `dbt build` connects to the right warehouse with no `--target` flag.

The second argument to `env_var` is a fallback. If you ever run dbt outside these containers, `DBT_TARGET` is unset and you silently get DuckDB — worth remembering if a "Snowflake" run mysteriously writes to a local file.

`dbt_base` does not set the variable, so it takes that DuckDB fallback.

---

## Why `build`, then `run` — not `up`

They do different jobs. Mix them up and it feels like Docker is broken.

**`docker compose build`** — bake the image. Reads the Dockerfile and does the install work. Saves a reusable image. **Nothing runs yet.** Do this the first time, and whenever `Dockerfile` or `requirements.txt` changes. Do **not** do it because you edited a SQL model; that file is mounted.

**`docker compose run --rm <service>`** — start a one-off container, apply the mounts, run your command, throw the container away. This is the daily command.

**`docker compose up`** — start containers as standing services. This repo has no server to keep running, so you will rarely want it. The services do set `stdin_open: true` and `tty: true`, which is what keeps `command: /bin/bash` from exiting instantly under `up`. Without those two lines all three containers would look like they crashed on startup.

`--rm` means "throw this container away when I exit." Without it, every `run` leaves a stopped container behind and Compose starts warning about orphans. The image and your files are untouched either way. List leftovers with `docker ps -a`.

---

## Daily loop (copy-paste)

From the repo root on your Mac:

```bash
# First time, or after Dockerfile / requirements.txt changes
docker compose build dbt_duckdb
```

DuckDB needs its source data built once. It is an embedded database, so there is no server and no credentials:

```bash
docker compose run --rm dbt_duckdb python /utils/load_raw.py
docker compose run --rm dbt_duckdb sh -c 'dbt deps && dbt build'
```

`load_raw.py` reads the three CSVs in `utils/duckdb/data/` and writes `raw.duckdb`. dbt then connects to `analytics.duckdb` with `raw.duckdb` attached read-only under the alias `raw`, which is how the sources resolve `raw.jaffle_shop.customers`. Run the loader first or the attach fails, because a read-only attach cannot create a missing file.

`dbt deps` is needed once per project: `packages.yml` requires `codegen`, which pulls in `dbt_utils`. Without it every command fails at parse time.

For an interactive shell instead:

```bash
docker compose run --rm dbt_duckdb bash
```

---

## Picture of the whole flow

```
your Mac:  dbt-docker/
           ├── Dockerfile              recipe
           ├── docker-compose.yaml     seating chart
           ├── requirements.txt        pip packages (baked into the image)
           ├── .dbt/profiles.yml  ──►  mounted at /root/.dbt
           ├── .ssh/*.p8          ──►  mounted at /root/.ssh
           ├── utils/duckdb/      ──►  mounted at /utils   (duckdb service only)
           ├── dbt-duckdb/        ──►  mounted at /app     (duckdb service)
           └── dbt-snowflake/     ──►  mounted at /app     (snowflake service)

docker compose build
        │
        ▼
     image   (Python 3.12 + dbt-core 1.12.4 + both adapters)

docker compose run --rm dbt_duckdb
        │
        ▼
     container, bash starts in /app
        you type: dbt deps / dbt build / ...
        │
        ▼
     DuckDB file in utils/    or    Snowflake over the network
```

Two layers, on purpose:

- **Image** = tools (Python, dbt, git, gcc). Rebuild when these change.
- **Volumes** = your files (models, profiles, key). Edit on the Mac; the container sees them. No rebuild.

---

## The Dockerfile, line by line

```dockerfile
FROM python:3.12-slim
```

Start from an official Python 3.12 Linux image. `slim` means a smaller Debian base with fewer preinstalled packages. Every later line adds a layer on top.

```dockerfile
RUN apt-get update -yqq && \
    apt-get install -yqq \
    git \
    gcc
```

Refresh Debian's package index, then install two things. `git` is needed because `dbt deps` clones packages from GitHub. `gcc` is a C compiler, needed when a Python dependency has no prebuilt wheel for this platform and must compile from source.

Both commands are in **one** `RUN` on purpose. If `update` ran in its own layer, Docker could reuse a stale cached package index on a later build and then fail to find packages.

On the flags: `-y` answers yes to prompts, which matters because a build has nobody to type "Y". `-qq` is quiet level 2. Note that `-qq` already implies `-y`, so the `y` is technically redundant, but writing it makes the intent visible. The tradeoff with `-qq` is that when a build breaks you have thrown away the output explaining why.

```dockerfile
RUN pip install --upgrade pip

COPY requirements.txt .
RUN pip install -r requirements.txt
```

Copy **only** that one file in, then install dbt. Ordered on purpose: Docker caches layers, so editing a SQL model does not re-run pip. Editing `requirements.txt` does.

```dockerfile
RUN mkdir -p /app
COPY ./ /app/
RUN chmod 777 -R /app
WORKDIR /app
```

Create `/app`, copy the repo into the image as a fallback snapshot, make it writable, and set the default directory.

Three notes. The `mkdir -p` is redundant, since both `COPY` and `WORKDIR` create the directory themselves; `-p` means "create parents as needed, and do not error if it already exists." The `COPY ./ /app/` snapshot is almost unused under Compose, because the volume mount then **covers** `/app` with your live folder. And `chmod 777` makes everything world-writable, which is more permission than this needs — `755` would do.

`WORKDIR /app` is the line you actually feel: it is why bash starts in `/app`.

---

## How dbt finds its warehouse from inside Docker

dbt does not magically know your warehouse. Inside the container it reads:

1. `/app/dbt_project.yml` → `profile: 'profiles_dbt_docker'`
2. `/root/.dbt/profiles.yml` → that profile, picking the output named by `DBT_TARGET`

For Snowflake that output points at `private_key_path: /root/.ssh/snowflake_key.p8`. For DuckDB it points at `/utils/analytics.duckdb`.

Those paths exist only because Compose mounts `./.dbt`, `./.ssh`, and `./utils/duckdb`. If dbt cannot find the profile or the key, the usual causes are:

- you are not in a compose `run` (wrong folder on the Mac, or a raw `docker run` with no volumes)
- `.ssh/snowflake_key.p8` is missing — generate it with `bash utils/snowflake/generate_key.sh`
- the project's `profile:` does not match the name in `profiles.yml`

The image does **not** contain your key. `.gitignore` keeps `.ssh/` and `.env` out of git.

### The Snowflake `.env`

Only `dbt_snowflake` loads an env file:

```yaml
    env_file:
      - path: .env
        required: false
```

`required: false` is why the DuckDB workflow still runs on a machine that has never created a `.env`. Copy `.env.example` to `.env` and fill in `SNOWFLAKE_ACCOUNT` and `SNOWFLAKE_USER`; the rest have defaults.

---

## Rebuild or not

| You changed | Rebuild? | Why |
| --- | --- | --- |
| `Dockerfile` | Yes | Recipe changed |
| `requirements.txt` | Yes | `pip install` happens at build time |
| SQL models, `dbt_project.yml` | No | Mounted from the project folder |
| `.dbt/profiles.yml` | No | Mounted |
| `.ssh/snowflake_key.p8` | No | Mounted |
| `.env` | No | Read at container start |
| `docker-compose.yaml` | No | Read fresh on every `run` |

After a rebuild, start a **new** `run`. An already-open container still has the old image.

---

## Other commands, when you need them

Typed **on the Mac**, from the repo root:

```bash
docker compose config          # validate the compose file and show it fully resolved
docker compose ps              # what is running right now
docker images                  # images on this machine
docker ps -a                   # all containers, including leftover `run` ones
docker compose down            # stop things started with `up`
```

`docker compose config` is the quickest way to catch a typo in a mount path. It fails loudly on things like a container path missing its leading slash.

---

## If something feels wrong

**`dbt: command not found` on the Mac**
You are not inside the container. dbt is only installed in the image. Prefix with `docker compose run --rm dbt_duckdb`.

**`Could not find profile named 'jaffle_shop'`**
The project's `dbt_project.yml` has a `profile:` that does not match the top-level key in `.dbt/profiles.yml`. Both projects here use `profiles_dbt_docker`.

**`dbt expects 2 package(s) ... found only 0`**
Run `dbt deps` first, inside the same service.

**DuckDB errors about a missing database file**
Run `docker compose run --rm dbt_duckdb python /utils/load_raw.py`. The read-only attach cannot create `raw.duckdb` for you.

**Snowflake auth fails**
Check that the public key registered correctly: run `desc user <you>` in Snowflake and compare `RSA_PUBLIC_KEY_FP` against the fingerprint printed by `generate_key.sh`. The most common mistake is pasting the `.pub` file verbatim; `ALTER USER` wants the body with the header, footer, and newlines stripped.

**I edited SQL and the container does not see it**
You need the compose volume. If you used a raw `docker run` without mounts, you are looking at the `COPY ./ /app/` snapshot from build time.

**The DuckDB UI does not open**
`utils/duckdb/ui.py` serves on port 4213, and no service publishes that port. Add a `ports` mapping to `dbt_duckdb` first.
