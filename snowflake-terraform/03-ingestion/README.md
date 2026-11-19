# 03 — Ingestion

These show up after the first query works. Each object is its own folder.

```text
03-ingestion/
  file-format/        TF_LEARN_CSV
  stage/              TF_LEARN_INT_STAGE
  resource-monitor/   optional Snowsight SQL (not applied)
  main.tf             wires format → stage
```


## Read in this order

1. [file-format](file-format/README.md) — how to parse a file
2. [stage](stage/README.md) — where the file sits
3. [resource-monitor](resource-monitor/README.md) — credit cap (optional)
4. `main.tf` — parent wiring


## Apply

From the repo root:

```bash
terraform apply
```

Then run `check.sql`. Loading a real file is optional.

If you want the credit cap, run `resource-monitor/resource_monitor.sql` in Snowsight as `ACCOUNTADMIN`.
