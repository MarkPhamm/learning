# Stage

Landing zone for files before `COPY INTO`.

| Kind | Storage | Resource |
| --- | --- | --- |
| Internal (this folder) | Snowflake-managed | `snowflake_stage_internal` |
| External | Your S3 / GCS / Azure | `snowflake_stage_external_s3` (and siblings) |

Load path: `PUT` a file → `COPY INTO` the table using `../file-format`.


## `versions.tf`

```hcl
terraform {
  required_providers {
    snowflake = {
      source = "snowflakedb/snowflake"
    }
  }
}
```

Declares the Snowflake provider. Version pin is at the repo root. Creates nothing.


## `variables.tf`

```hcl
variable "database_name"   { type = string }
variable "schema_name"     { type = string }
variable "file_format_fqn" { type = string }
```

`file_format_fqn` is `module.file_format.fully_qualified_name`. The stage `format_name` field wants `"DB"."SCHEMA"."FORMAT"`.


## `main.tf`

```hcl
resource "snowflake_stage_internal" "this" {
  database = var.database_name
  schema   = var.schema_name
  name     = "TF_LEARN_INT_STAGE"
  comment  = "Lesson 03 — internal stage that reuses the CSV file format"

  file_format {
    format_name = var.file_format_fqn
  }
}
```

`this` is the Terraform label. Snowflake object is `TF_LEARN_INT_STAGE`. State: `module.ingestion.module.stage.snowflake_stage_internal.this`.

| Argument | Meaning |
| --- | --- |
| `database` / `schema` / `name` | Nesting, same as a table. |
| `file_format.format_name` | FQN of the CSV format. |


## Snowsight SQL

```sql
USE ROLE SYSADMIN;

CREATE STAGE TF_LEARN_DB.RAW.TF_LEARN_INT_STAGE
    FILE_FORMAT = TF_LEARN_DB.RAW.TF_LEARN_CSV
    COMMENT = 'Lesson 03 — internal stage that reuses the CSV file format';
```

Then, if you have a local CSV:

```sql
-- PUT is typically run from snowsql, not a Snowsight worksheet
-- PUT file:///absolute/path/customers.csv @TF_LEARN_DB.RAW.TF_LEARN_INT_STAGE;

COPY INTO TF_LEARN_DB.RAW.CUSTOMERS
    FROM @TF_LEARN_DB.RAW.TF_LEARN_INT_STAGE;
```


## `outputs.tf`

```hcl
output "fully_qualified_name" {
  value = snowflake_stage_internal.this.fully_qualified_name
}
```

| Output | Example | Use |
| --- | --- | --- |
| `fully_qualified_name` | `"TF_LEARN_DB"."RAW"."TF_LEARN_INT_STAGE"` | `PUT @...` / `COPY INTO ... FROM @...` |

Next: [resource-monitor](../resource-monitor/README.md)
