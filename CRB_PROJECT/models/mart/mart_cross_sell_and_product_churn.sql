WITH customer_transactions AS (
    SELECT
        customer_id,
        product_id,
        payment_month
    FROM
        {{ref('stg_transactions')}}
),
product_churn AS (
    SELECT
        product_id,
        COUNT(DISTINCT customer_id) AS churned_customers
    FROM
        customer_transactions
    WHERE
        payment_month < CURRENT_DATE - INTERVAL '30 Days'
    GROUP BY
        product_id
),
cross_sell AS (
    SELECT
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
)
SELECT
    cs.customer_id,
    cs.product_id_1,
    cs.product_id_2,
    COUNT(DISTINCT cs.product_id_2) AS cross_sell_opportunities,
    pc.churned_customers
FROM
    cross_sell cs
LEFT JOIN
    product_churn pc
ON
    cs.product_id_1 = pc.product_id
GROUP BY
    cs.customer_id, cs.product_id_1, cs.product_id_2, pc.churned_customers
ORDER BY
    cross_sell_opportunities DESC, pc.churned_customers DESC