
  
    

        create or replace transient table PROJECT_DB.PROJECT_SCHEMA_stage.stg_customers
         as
        (SELECT
    customer_id,
    REPLACE(REGEXP_REPLACE(customername, '\\(.*?\\)', ''),',','') AS customer_name,
    company
FROM PROJECT_DB.STAGE.CUSTOMERS_DATA
WHERE customer_id IS NOT NULL
        );
      
  