# Template
# resource "snowflake_file_format_csv" "this" {
#   database = var.database_name
#   schema   = var.schema_name
#   name     = "A"
#   comment  = "B"
#
#   skip_header                  = 1
#   field_delimiter              = ","
#   field_optionally_enclosed_by = "\""
#   trim_space                   = true/false
#   empty_field_as_null          = true/false
#   null_if                      = ["", "NULL"]
# }

# Use the typed resources (snowflake_file_format_csv, _json, ...).
# The old snowflake_file_format resource is deprecated.

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
