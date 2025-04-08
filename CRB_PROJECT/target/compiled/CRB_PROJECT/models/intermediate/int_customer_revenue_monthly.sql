

WITH monthly_revenue AS (
  SELECT
    t.CUSTOMER_ID,
    c.CUSTOMER_NAME,
    DATE_TRUNC('MONTH', t.PAYMENT_MONTH) AS MONTH,
    SUM(t.REVENUE) AS TOTAL_REVENUE,
    COUNT(DISTINCT t.PRODUCT_ID) AS PRODUCT_COUNT
  FROM PROJECT_DB.PROJECT_SCHEMA_stage.stg_transactions t
  JOIN PROJECT_DB.PROJECT_SCHEMA_stage.stg_customers c ON t.CUSTOMER_ID = c.CUSTOMER_ID
  GROUP BY 1, 2, 3
)

SELECT
  CUSTOMER_ID,
  CUSTOMER_NAME,
  MONTH,
  TOTAL_REVENUE,
  PRODUCT_COUNT,
  LAG(TOTAL_REVENUE, 12) OVER (PARTITION BY CUSTOMER_ID ORDER BY MONTH) AS PREV_YEAR_REVENUE,
  LAG(TOTAL_REVENUE, 1) OVER (PARTITION BY CUSTOMER_ID ORDER BY MONTH) AS PREV_MONTH_REVENUE
FROM monthly_revenue