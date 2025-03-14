WITH customers AS (
    SELECT 
        customer_id,
        customer_name,
        company
    FROM PROJECT_DB.PROJECT_SCHEMA.stg_customers
),
last_payment AS (
    SELECT
        customer_id,
        MAX(payment_month) AS last_payment_date
    FROM PROJECT_DB.PROJECT_SCHEMA.stg_transactions
    WHERE revenue_type = 1
    GROUP BY customer_id
),
churned_customers AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.company,
        lp.last_payment_date
    FROM customers c
    JOIN last_payment lp
        ON c.customer_id = lp.customer_id
    WHERE lp.last_payment_date >= (CURRENT_DATE - INTERVAL '1 year')::DATE
)

SELECT * FROM churned_customers