
  
    

        create or replace transient table PROJECT_DB.PROJECT_SCHEMA_stage.stg_locations
         as
        (SELECT
    * 
FROM PROJECT_DB.STAGE.LOCATIONS_DATA
WHERE 
    customer_id 
IS 
    NOT NULL
        );
      
  