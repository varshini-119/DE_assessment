
  
    

        create or replace transient table PROJECT_DB.PROJECT_SCHEMA_stage.stg_transactions
         as
        (SELECT
    * 
FROM PROJECT_DB.STAGE.TRANSACTIONS_DATA
WHERE
    customer_id 
IS 
    NOT NULL
        );
      
  