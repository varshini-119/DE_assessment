SELECT
    * 
FROM {{source("crb_data","TRANSACTIONS_DATA")}}
WHERE
    customer_id 
IS 
    NOT NULL
