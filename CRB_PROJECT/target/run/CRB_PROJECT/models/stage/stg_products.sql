
  
    

        create or replace transient table PROJECT_DB.PROJECT_SCHEMA_stage.stg_products
         as
        (SELECT 
    *
FROM PROJECT_DB.STAGE.PRODUCTS_DATA
        );
      
  