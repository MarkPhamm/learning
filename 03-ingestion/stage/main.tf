# Template
# resource "snowflake_stage_internal" "this" {
#   database = var.database_name
#   schema   = var.schema_name
#   name     = "A"
#   comment  = "B"
#
#   file_format {
#     format_name = var.file_format_fqn
#   }
# }

# Internal stage: Snowflake-managed storage. You PUT files here.
# External stage: your S3 / GCS / Azure bucket
#   (snowflake_stage_external_s3 and siblings).
# The legacy snowflake_stage resource is deprecated.

resource "snowflake_stage_internal" "this" {
  database = var.database_name
  schema   = var.schema_name
  name     = "TF_LEARN_INT_STAGE"
  comment  = "Lesson 03 — internal stage that reuses the CSV file format"

  file_format {
    format_name = var.file_format_fqn
  }
}
