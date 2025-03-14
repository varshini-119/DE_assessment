
  
    

        create or replace transient table PROJECT_DB.PROJECT_SCHEMA_mart.mart_new_and_churned_customers
         as
        (WITH purchases AS (
    SELECT 
        customer_id,
        MIN(payment_month) AS first_purchase_month,
        MAX(payment_month) AS last_purchase_month
    FROM 
        PROJECT_DB.PROJECT_SCHEMA_stage.stg_transactions
    GROUP BY 
        customer_id
),
new_and_churned_customers AS (
    SELECT
        t.payment_month,
        COUNT(DISTINCT CASE WHEN p.first_purchase_month = t.payment_month THEN t.customer_id END) AS new_customers,
        COUNT(DISTINCT CASE WHEN p.last_purchase_month < t.payment_month THEN t.customer_id END) AS churned_customers
    FROM 
        PROJECT_DB.PROJECT_SCHEMA_stage.stg_transactions t
    LEFT JOIN 
        purchases p ON t.customer_id = p.customer_id
    GROUP BY 
        t.payment_month
)
SELECT
    *
FROM
    new_and_churned_customers
ORDER BY
    payment_month
        );
      
  