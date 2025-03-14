SELECT
    customer_id,
    REPLACE(REGEXP_REPLACE(customername, '\\(.*?\\)', ''),',','') AS customer_name,
    company
FROM PROJECT_DB.STAGE.CUSTOMERS_DATA
WHERE customer_id IS NOT NULL