WITH customer_data AS (
    SELECT
        customer_id,
        customer_name
    FROM PROJECT_DB.PROJECT_SCHEMA_stage.stg_customers
),
product_data AS (
    SELECT
        product_id,
        product_family,
        product_sub_family
    FROM PROJECT_DB.PROJECT_SCHEMA_stage.stg_products
),
transaction_data AS (
    SELECT
        customer_id,
        product_id,
        payment_month,
        revenue,
        SUM(revenue) OVER(PARTITION BY product_id) AS total_revenue,
        LAG(revenue) OVER (PARTITION BY customer_id ORDER BY payment_month) AS prev_revenue,
        CASE
            WHEN revenue >= prev_revenue THEN 'Expansion'
            WHEN revenue < prev_revenue THEN 'Contraction'
        END AS revenue_trend
    FROM PROJECT_DB.PROJECT_SCHEMA_stage.stg_transactions
),
customer_ranks AS (
    SELECT * FROM PROJECT_DB.PROJECT_SCHEMA_mart.mart_rank_customers
),
product_ranks AS (
    SELECT * FROM PROJECT_DB.PROJECT_SCHEMA_mart.mart_rank_products
),

crb AS (
    SELECT
        t.customer_id,
        t.product_id,
        p.product_family,
        p.product_sub_family,
        t.revenue,
        t.prev_revenue,
        t.revenue_trend,
        l.region,
        l.country,
        cr.revenue_rank AS customer_rank,
        pr.revenue_rank AS product_rank
    FROM transaction_data t
    LEFT JOIN customer_data c ON t.customer_id = c.customer_id
    LEFT JOIN product_data p ON t.product_id = p.product_id
    LEFT JOIN PROJECT_DB.PROJECT_SCHEMA_stage.stg_locations l ON t.customer_id = l.customer_id
    LEFT JOIN customer_ranks cr ON t.customer_id = cr.customer_id
    LEFT JOIN product_ranks pr ON t.product_id = pr.product_id
    GROUP BY 
        t.customer_id, 
        t.product_id, 
        p.product_family, 
        p.product_sub_family, 
        t.revenue, 
        t.prev_revenue, 
        t.revenue_trend, 
        l.region, 
        l.country, 
        t.total_revenue,
        cr.revenue_rank,
        pr.revenue_rank
)

SELECT * FROM crb