# Template
# resource "snowflake_resource_monitor" "this" {
#   provider        = snowflake.accountadmin
#   name            = "A"
#   credit_quota    = 10
#   frequency       = "MONTHLY/DAILY/WEEKLY/YEARLY/NEVER"
#   start_timestamp = "IMMEDIATELY"
#   notify_triggers = [50]
#   suspend_trigger = 100
# }

# Reference only — not applied. See README.md and resource_monitor.sql.
#
# resource "snowflake_resource_monitor" "this" {
#   provider        = snowflake.accountadmin
#   name            = "TF_LEARN_RM"
#   credit_quota    = 10
#   frequency       = "MONTHLY"
#   start_timestamp = "IMMEDIATELY"
#   notify_triggers = [50]
#   suspend_trigger = 100
# }
#
# Then attach it to TF_LEARN_WH (also ACCOUNTADMIN):
#   resource_monitor = snowflake_resource_monitor.this.fully_qualified_name
