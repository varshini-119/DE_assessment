WITH products AS (
    SELECT
        p.product_id,
        p.product_family, 
        p.product_sub_family,
    FROM PROJECT_DB.PROJECT_SCHEMA_stage.stg_products p
),
total_revenue AS (
    SELECT
        t.product_id,
        SUM(t.revenue) AS total_revenue,
        RANK() OVER(ORDER BY SUM(t.revenue) DESC) AS revenue_rank
    FROM PROJECT_DB.PROJECT_SCHEMA_stage.stg_transactions t
    JOIN products p ON t.product_id = p.product_id
    GROUP BY t.product_id
)

SELECT * 
FROM total_revenue
ORDER BY revenue_rank