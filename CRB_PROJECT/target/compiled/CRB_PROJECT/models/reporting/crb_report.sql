WITH revenue AS (
    SELECT
        payment_month,
        SUM(revenue) AS total_revenue
    FROM
        PROJECT_DB.PROJECT_SCHEMA_stage.stg_transactions
    GROUP BY
        payment_month
),
customer_transactions AS (
    SELECT
        customer_id,
        product_id,
        payment_month
    FROM
        PROJECT_DB.PROJECT_SCHEMA_stage.stg_transactions
),
product_churn_lm AS (
    SELECT
        payment_month,
        product_id,
        COUNT(DISTINCT customer_id) AS churned_customers_lm
    FROM
        customer_transactions
    WHERE
        payment_month < CURRENT_DATE - INTERVAL '30 Days'
    GROUP BY
        payment_month, product_id
),
cross_sell AS (
    SELECT
        ct1.payment_month,
        ct1.customer_id,
        ct1.product_id AS product_id_1,
        ct2.product_id AS product_id_2
    FROM
        customer_transactions ct1
    JOIN
        customer_transactions ct2
    ON
        ct1.customer_id = ct2.customer_id
    WHERE
        ct1.product_id <> ct2.product_id
),
new_and_churned_customers AS (
    SELECT
        t.payment_month,
        COUNT(DISTINCT CASE WHEN p.first_purchase_month = t.payment_month THEN t.customer_id END) AS new_customers,
        COUNT(DISTINCT CASE WHEN p.last_purchase_month < t.payment_month THEN t.customer_id END) AS churned_customers
    FROM 
        PROJECT_DB.PROJECT_SCHEMA_stage.stg_transactions t
    LEFT JOIN 
        (SELECT customer_id, MIN(payment_month) AS first_purchase_month, MAX(payment_month) AS last_purchase_month
         FROM PROJECT_DB.PROJECT_SCHEMA_stage.stg_transactions
         GROUP BY customer_id) p
    ON t.customer_id = p.customer_id
    GROUP BY 
        t.payment_month
),
grr_nrr AS (
    SELECT
        payment_month,
        grr,
        nrr
    FROM
        PROJECT_DB.PROJECT_SCHEMA_mart.mart_nrr_grr
)
SELECT
    r.payment_month,
    r.total_revenue,
    pc.churned_customers_lm AS product_churned_customers,
    nc.churned_customers AS churned_customers,
    gn.grr,
    nc.new_customers,
    cs.cross_sell_opportunities,
    gn.nrr
FROM
    revenue r
LEFT JOIN
    (SELECT payment_month, SUM(churned_customers_lm) AS churned_customers_lm
     FROM product_churn_lm
     GROUP BY payment_month) pc ON r.payment_month = pc.payment_month
LEFT JOIN
    new_and_churned_customers nc ON r.payment_month = nc.payment_month
LEFT JOIN
    (SELECT payment_month, COUNT(product_id_2) AS cross_sell_opportunities
     FROM cross_sell
     GROUP BY payment_month) cs ON r.payment_month = cs.payment_month
LEFT JOIN
    grr_nrr gn ON r.payment_month = gn.payment_month
ORDER BY
    r.payment_month