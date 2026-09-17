# duckdb_dbt_v2

A small, independent dbt **v2** (formerly Fusion) sample on DuckDB. It is not a fork of `duckdb-dbt-metricflow`.

DuckDB is CLI-only in v2 and is bundled with `pip install dbt`.

## Setup

```bash
python3.12 -m venv .venv
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
