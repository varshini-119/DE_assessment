WITH customers AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.company
    FROM {{ ref('stg_customers') }} c
),
total_revenue AS (
    SELECT
        t.customer_id,
        SUM(t.revenue) AS total_revenue,
        RANK() OVER(ORDER BY SUM(t.revenue) DESC) AS revenue_rank
    FROM {{ref('stg_transactions')}} t
    JOIN customers c ON t.customer_id = c.customer_id
    GROUP BY t.customer_id
)

SELECT * 
FROM total_revenue
ORDER BY revenue_rank