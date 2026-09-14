# dbt-docker

dbt running in Docker against two warehouses, DuckDB locally and Snowflake
remotely, using the jaffle shop tutorial dataset. Built as a way to relearn
Docker alongside dbt.

## Requirements

Docker Desktop is the only thing you need installed on the host:

```bash
brew install --cask docker-desktop
open -a Docker
```

Everything else, dbt included, lives inside the image.

## Layout

```
.dbt/profiles.yml    connection profiles, mounted at /root/.dbt
.ssh/                snowflake private key, gitignored, mounted at /root/.ssh
dbt-duckdb/          dbt project for the DuckDB target
dbt-snowflake/       dbt project for the Snowflake target
utils/duckdb/        scripts that build the local DuckDB source data
utils/snowflake/     SQL to load Snowflake sources and register the auth key
```

The two dbt projects start as copies of each other. They are kept separate
because Snowflake and DuckDB do not share a SQL dialect, so the model code is
expected to drift apart. The Docker image is identical for both; both adapters
are installed side by side.

## Services

Three Compose services share one image:

| Service | Project at /app | Target |
| --- | --- | --- |
| `dbt_base` | repo root | falls back to DuckDB |
| `dbt_duckdb` | `dbt-duckdb/` | `dbt_duckdb_dev` |
| `dbt_snowflake` | `dbt-snowflake/` | `dbt_snowflake_dev` |

Each service sets `DBT_TARGET`, which `profiles.yml` reads through `env_var`.
That means plain `dbt` commands connect to the right warehouse with no flags:

```bash
docker compose run --rm dbt_duckdb dbt build
docker compose run --rm dbt_snowflake dbt build
```

Use `docker compose run --rm <service>` for a one-off command and
`docker compose run --rm <service> bash` for an interactive shell.

## DuckDB

DuckDB is an embedded database, so there is no server and no credentials. The
data lives in two files under `utils/duckdb/`, both gitignored and both
rebuildable from the CSVs in `utils/duckdb/data/`.

```bash
docker compose run --rm dbt_duckdb python /utils/load_raw.py
docker compose run --rm dbt_duckdb sh -c 'dbt deps && dbt build'
```

`load_raw.py` builds `raw.duckdb` from the three CSVs. dbt then connects to
`analytics.duckdb` with `raw.duckdb` attached read-only under the alias `raw`,
which is what lets the sources resolve `raw.jaffle_shop.customers`. Run
`load_raw.py` first, or the attach fails because the file does not exist.

`utils/duckdb/ui.py` opens DuckDB's browser UI against the built models. It
serves on port 4213, which the `dbt_duckdb` service does not currently publish,
so running it inside the container is not reachable from the host without
adding a `ports` mapping.

## Snowflake

Snowflake needs three things set up once: source data, an auth key, and a
`.env` file.

Load the sources by running `utils/snowflake/raw_data.sql` in a Snowflake
worksheet. It creates the `raw` and `analytics` databases and copies the same
three tables from the public dbt tutorial bucket.

Generate the key pair, which uses the PKCS#8 format Snowflake requires:

```bash
bash utils/snowflake/generate_key.sh
```

The private key is written to `.ssh/snowflake_key.p8` and never leaves your
machine. The script prints the public key body and a fingerprint. Paste the
body into `utils/snowflake/setup_key.sql`, replace `your_username`, and run it
in Snowflake. Compare `RSA_PUBLIC_KEY_FP` from `desc user` against the printed
fingerprint to confirm the key registered correctly.

Then fill in your account details:

```bash
cp .env.example .env
```

Only `SNOWFLAKE_ACCOUNT` and `SNOWFLAKE_USER` are required; the rest have
defaults. The account identifier is the `orgname-account_name` form, not the
full URL. `.env` is gitignored and is loaded only by the `dbt_snowflake`
service.

Verify the connection with:

```bash
docker compose run --rm dbt_snowflake dbt debug
```

## Credentials

`.dbt/profiles.yml` contains no secrets. Every connection value is read from
the environment through `env_var`, so the profile is safe to commit. The two
things that must never be committed, `.ssh/` and `.env`, are both gitignored.

## Notes

`dbt-duckdb` is pinned to 1.11.0 rather than 1.12.0. Adapters release on their
own cadence and lag `dbt-core`, so matching version numbers across the two will
often fail to resolve.

Run `dbt deps` once per project before the first build. `packages.yml` requires
`codegen`, which pulls in `dbt_utils`.
