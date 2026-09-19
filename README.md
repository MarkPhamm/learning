# duckdb_dbt_v2

A small, independent dbt **v2** (formerly Fusion) sample on DuckDB. It is not a fork of `duckdb-dbt-metricflow`.

DuckDB is CLI-only in v2 and is bundled with both `pip install dbt` and `pip install dbt-oss`.

## Distributions

v2 ships two local installs. The project files are the same; the difference is what the binary can do with them.

| | Full `dbt` (`.venv`) | `dbt-oss` (`.venv_oss`) |
|---|---|---|
| License | dbt Product License | Apache 2.0 |
| Pin file | `requirements.txt` (`dbt==2.0.4`) | `requirements-oss.txt` (`dbt-oss==2.0.5`) |
| `dbt build`, Docs v2, Information Schema | Yes | Yes |
| `--static-analysis strict` CLI flag | Runs the engine | Accepted, then skipped with a warning |
| Column types and column-level lineage | Yes, after a strict compile | No (`dbt show --info column_lineage` is empty; Docs v2 hides CLL) |
| `dbt lint`, LSP / VS Code SQL comprehension | Yes | No |

OSS includes the Docs v2 site and table-level DAG. Column-level lineage needs the static analysis engine, which is only in the full `dbt` package.

```bash
# Full dbt: populate lineage, then export Docs v2 without recompiling in baseline
dbt compile --write-index --generate-info-schema --static-analysis strict
dbt docs generate --no-compile
dbt show --info column_lineage
```

On OSS the same flags compile and generate docs, but you get:

```text
static analysis was requested with `--static-analysis strict` but did not run:
this distribution of dbt OSS does not include the static analysis engine.
```

## Setup

Full dbt (recommended for lineage and lint):

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

export DBT_PROFILES_DIR="$PWD"
dbt --version          # dbt 2.0.4
dbt debug
dbt build
dbt show --select orders --limit 10
dbt lint
dbt docs generate
```

dbt OSS (Apache 2.0 runtime only):

```bash
python3 -m venv .venv_oss
source .venv_oss/bin/activate
pip install -r requirements-oss.txt

export DBT_PROFILES_DIR="$PWD"
dbt --version          # dbt-oss 2.0.5
dbt build --target-path target_oss
dbt docs generate --target-path target_oss
```

`dbt sl validate` needs a dbt platform project. This sample still defines Semantic Layer YAML so you can inspect metrics with:

```bash
dbt list --resource-type metric
dbt list --resource-type semantic_model
```

## Project

Seeds load a tiny cafe dataset. Staging models clean it. Marts are `customers` and `orders`.

| Layer | Models |
|---|---|
| seeds | `raw_customers`, `raw_orders`, `raw_products` |
| staging | `stg_customers`, `stg_orders`, `stg_products` |
| marts | `customers`, `orders` |

`orders` uses the latest Semantic Layer spec: simple metrics (`order_count`, `revenue`, `average_order_value`) plus a derived metric (`revenue_per_order`).
