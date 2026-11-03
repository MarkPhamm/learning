module "file_format" {
  source        = "./file-format"
  database_name = var.database_name
  schema_name   = var.schema_name
}

module "stage" {
  source          = "./stage"
  database_name   = var.database_name
  schema_name     = var.schema_name
  file_format_fqn = module.file_format.fully_qualified_name
}

# resource-monitor/ is not a Terraform module. Run its SQL in Snowsight.
