SELECT
    customer_id,
    REPLACE(REGEXP_REPLACE(customername, '\\(.*?\\)', ''),',','') AS customer_name,
    company
FROM {{source("crb_data", "CUSTOMERS_DATA")}}
WHERE customer_id IS NOT NULL