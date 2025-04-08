{{
  config(
    materialized = 'table',
    schema = 'intermediate'
  )
}}

SELECT
  p.PRODUCT_ID,
  p.PRODUCT_FAMILY,
  p.PRODUCT_SUB_FAMILY,
  DATE_TRUNC('MONTH', t.PAYMENT_MONTH) AS MONTH,
  SUM(t.REVENUE) AS TOTAL_REVENUE,
  COUNT(DISTINCT t.CUSTOMER_ID) AS CUSTOMER_COUNT,
  SUM(t.QUANTITY) AS TOTAL_QUANTITY,
  RANK() OVER (ORDER BY SUM(t.REVENUE) DESC) AS REVENUE_RANK
FROM {{ ref('stg_transactions') }} t
JOIN {{ ref('stg_products') }} p ON t.PRODUCT_ID = p.PRODUCT_ID
GROUP BY 1, 2, 3, 4