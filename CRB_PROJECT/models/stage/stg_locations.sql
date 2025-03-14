SELECT
    * 
FROM {{source("crb_data","LOCATIONS_DATA")}}
WHERE 
    customer_id 
IS 
    NOT NULL
