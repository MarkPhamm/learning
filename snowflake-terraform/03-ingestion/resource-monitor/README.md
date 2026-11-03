# Resource monitor

Credit quota plus triggers (notify at 50%, suspend at 100%). Warehouses do not cap themselves.

Creating or attaching one needs `ACCOUNTADMIN`. This folder is **not** applied by Terraform — an `ACCOUNTADMIN` provider alias would break `plan` for anyone who skipped that grant.

There is no `versions.tf` or `outputs.tf`. Nothing here is a live module.


## `main.tf`

Commented HCL only — a picture of what Terraform would look like later:

```hcl
# resource "snowflake_resource_monitor" "this" {
#   provider        = snowflake.accountadmin
#   name            = "TF_LEARN_RM"
#   credit_quota    = 10
#   frequency       = "MONTHLY"
#   start_timestamp = "IMMEDIATELY"
#   notify_triggers = [50]
#   suspend_trigger = 100
# }
```

| Argument | Meaning |
| --- | --- |
| `name` | Account-unique identifier (`TF_LEARN_RM`). Same as FQN — no parent database. |
| `credit_quota` | Credits per interval before 100%. |
| `frequency` | When the quota resets (`MONTHLY`). |
| `notify_triggers` / `suspend_trigger` | Percent of quota. |

## Snowsight SQL

Same as `resource_monitor.sql`. Role must be `ACCOUNTADMIN`:

```sql
USE ROLE ACCOUNTADMIN;

CREATE RESOURCE MONITOR TF_LEARN_RM
    CREDIT_QUOTA = 10
    FREQUENCY = MONTHLY
    START_TIMESTAMP = IMMEDIATELY
    TRIGGERS
        ON 50 PERCENT DO NOTIFY
        ON 100 PERCENT DO SUSPEND;

ALTER WAREHOUSE TF_LEARN_WH SET RESOURCE_MONITOR = TF_LEARN_RM;
```
