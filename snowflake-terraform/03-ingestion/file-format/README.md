# File format

Named parse recipe for `COPY INTO` (delimiter, header, null tokens). Metadata only until a stage or `COPY` uses it.

Use typed resources (`snowflake_file_format_csv`, `_json`, …). Untyped `snowflake_file_format` is deprecated.


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
variable "database_name" { type = string }
variable "schema_name"   { type = string }
```

Parent sets these from lesson 01 (`TF_LEARN_DB`, `RAW`).


## `main.tf`

```hcl
resource "snowflake_file_format_csv" "this" {
  database = var.database_name
  schema   = var.schema_name
  name     = "TF_LEARN_CSV"
  comment  = "Lesson 03 — CSV with header row, comma fields, quoted strings"

  skip_header                  = 1
  field_delimiter              = ","
  field_optionally_enclosed_by = "\""
  trim_space                   = "true"
  empty_field_as_null          = "true"
  null_if                      = ["", "NULL"]
}
```

`this` is the Terraform label. Snowflake object is `TF_LEARN_CSV`. State: `module.ingestion.module.file_format.snowflake_file_format_csv.this`.

| Argument | Meaning |
| --- | --- |
| `database` / `schema` / `name` | Nesting, same as a table. |
| `skip_header` | First row is column names, not data. |
| `field_delimiter` / `field_optionally_enclosed_by` | Comma fields, quoted strings. |
| `empty_field_as_null` / `null_if` | Empty or `NULL` text → SQL NULL. |


## Snowsight SQL

```sql
USE ROLE SYSADMIN;

CREATE FILE FORMAT TF_LEARN_DB.RAW.TF_LEARN_CSV
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_DELIMITER = ','
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    EMPTY_FIELD_AS_NULL = TRUE
    NULL_IF = ('', 'NULL')
    COMMENT = 'Lesson 03 — CSV with header row, comma fields, quoted strings';
```


## `outputs.tf`

```hcl
output "fully_qualified_name" {
  value = snowflake_file_format_csv.this.fully_qualified_name
}
```

| Output | Example | Use |
| --- | --- | --- |
| `fully_qualified_name` | `"TF_LEARN_DB"."RAW"."TF_LEARN_CSV"` | Stage `file_format { format_name = ... }` |

No `name` output — the stage needs the FQN, not `TF_LEARN_CSV` alone.

Next: [stage](../stage/README.md)
