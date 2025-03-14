WITH transactional_data AS (
    SELECT
        customer_id,
        product_id,
        payment_month,
        revenue,
        LAG(revenue) OVER (PARTITION BY customer_id ORDER BY payment_month) AS prev_revenue,
        CASE
            WHEN revenue >= prev_revenue THEN 'Expansion'
            WHEN revenue < prev_revenue THEN 'Contraction'
        END AS revenue_trend
    FROM {{ ref('stg_transactions') }}
)
SELECT 
    payment_month, 
    SUM(revenue) AS revenue_lost 
FROM transactional_data 
WHERE revenue_trend='Contraction' GROUP BY payment_month ORDER BY payment_month
