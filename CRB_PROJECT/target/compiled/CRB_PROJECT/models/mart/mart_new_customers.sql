-- WITH customers AS (
--     SELECT customer_id, customer_name, company
--     FROM PROJECT_DB.PROJECT_SCHEMA.stg_customers
-- ),
-- first_payment AS (
--     SELECT customer_id, MIN(payment_month)::DATE AS first_payment_date
--     FROM PROJECT_DB.PROJECT_SCHEMA.stg_transactions
--     GROUP BY customer_id
-- ),
-- new_customers AS (
--     SELECT c.customer_id, c.customer_name, c.company, fp.first_payment_date
--     FROM customers c
--     JOIN first_payment fp ON c.customer_id = fp.customer_id
--     WHERE fp.first_payment_date >= DATEADD(day, -365, CURRENT_DATE)
-- )
-- SELECT * FROM new_customers



WITH purchases AS (
    SELECT customer_id,
    MIN(payment_month) AS first_purchase_month,
    MAX(payment_month) AS last_purchase_month
    FROM PROJECT_DB.PROJECT_SCHEMA.stg_transactions
    GROUP BY customer_id
)
SELECT
    t.payment_month,
    COUNT(DISTINCT CASE WHEN p.first_purchase_month = t.payment_month THEN t.customer_id END) AS new_customers,
    COUNT(DISTINCT CASE WHEN p.last_purchase_month < t.payment_month THEN t.customer_id END) AS churned_customers
FROM stg_transactions t
LEFT JOIN purchases p ON t.customer_id = p.customer_id
GROUP BY t.payment_month
ORDER BY t.payment_month