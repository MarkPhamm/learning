-- Run in Snowsight after terraform apply. Role: SYSADMIN.

SHOW FILE FORMATS IN SCHEMA TF_LEARN_DB.RAW;
SHOW STAGES IN SCHEMA TF_LEARN_DB.RAW;

-- Resource monitor (only if you ran resource-monitor/resource_monitor.sql). Role: ACCOUNTADMIN.
-- SHOW RESOURCE MONITORS LIKE 'TF_LEARN_RM';

-- Optional load path once you have a local CSV:
-- PUT file:///absolute/path/customers.csv @TF_LEARN_DB.RAW.TF_LEARN_INT_STAGE;
-- COPY INTO TF_LEARN_DB.RAW.CUSTOMERS
--   FROM @TF_LEARN_DB.RAW.TF_LEARN_INT_STAGE
--   FILE_FORMAT = (FORMAT_NAME = TF_LEARN_DB.RAW.TF_LEARN_CSV);
