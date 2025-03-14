WITH newlogos AS (
    SELECT 
        EXTRACT(YEAR FROM TO_DATE(payment_month)) AS fiscal_year,
        COUNT(DISTINCT customer_id) AS new_logos 
    FROM
        {{ref("stg_transactions")}}
    GROUP BY fiscal_year
)
SELECT * FROM newlogos 
ORDER BY fiscal_year