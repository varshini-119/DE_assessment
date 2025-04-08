
  
    

        create or replace transient table PROJECT_DB.PROJECT_SCHEMA_report.final_report
         as
        (WITH base_transactions AS (
    SELECT
        customer_id,
        product_id,
        DATE_TRUNC('MONTH', payment_month) AS payment_month,
        revenue,
        revenue_type
    FROM PROJECT_DB.PROJECT_SCHEMA_stage.stg_transactions
),

fiscal_calculation AS (
    SELECT DISTINCT
        payment_month,
        CASE 
            WHEN DATE_PART('month', payment_month) BETWEEN 1 AND 3 
            THEN DATEADD('year', -1, DATE_TRUNC('year', payment_month))
            ELSE DATE_TRUNC('year', payment_month)
        END AS fiscal_year
    FROM base_transactions
),

customer_movement AS (
    SELECT
        t.customer_id,
        c.customer_name,
        t.payment_month,
        fc.fiscal_year,
        SUM(t.revenue) AS current_arr,
        SUM(CASE WHEN t.revenue_type = 1 THEN t.revenue ELSE 0 END) AS upsold_arr,
        LAG(SUM(t.revenue), 1) OVER (PARTITION BY t.customer_id ORDER BY t.payment_month) AS prev_arr,
        COUNT(DISTINCT t.product_id) AS product_count,
        LAG(COUNT(DISTINCT t.product_id), 1) OVER (PARTITION BY t.customer_id ORDER BY t.payment_month) AS prev_product_count,
        MAX(CASE WHEN c.company IS NOT NULL THEN 1 ELSE 0 END) AS is_logo
    FROM base_transactions t
    JOIN PROJECT_DB.PROJECT_SCHEMA_stage.stg_customers c ON t.customer_id = c.customer_id
    JOIN fiscal_calculation fc ON t.payment_month = fc.payment_month
    GROUP BY 1, 2, 3, 4
),

cross_sell_revenue AS (
    SELECT 
        t.payment_month,
        SUM(t.revenue) AS cross_sell_revenue
    FROM PROJECT_DB.PROJECT_SCHEMA_stage.stg_transactions t
    WHERE EXISTS (
        SELECT 1
        FROM PROJECT_DB.PROJECT_SCHEMA_stage.stg_transactions sub
        WHERE sub.customer_id = t.customer_id
          AND sub.payment_month = t.payment_month
        GROUP BY sub.customer_id, sub.payment_month
        HAVING COUNT(DISTINCT sub.product_id) > 1
    )
    GROUP BY t.payment_month
),

revenue_movement AS (
    SELECT
        cm.payment_month,
        cm.fiscal_year,

        -- Customer Metrics
        COUNT(DISTINCT CASE WHEN cm.prev_arr IS NULL AND cm.current_arr > 0 THEN cm.customer_id END) AS new_logos,
        COUNT(DISTINCT CASE WHEN cm.current_arr = 0 AND cm.prev_arr > 0 THEN cm.customer_id END) AS customer_churn,
        COUNT(DISTINCT CASE WHEN cm.product_count < cm.prev_product_count THEN cm.customer_id END) AS product_churn,

        -- Revenue Metrics
        SUM(CASE WHEN cm.prev_arr IS NULL THEN cm.current_arr ELSE 0 END) AS new_arr,
        SUM(cm.upsold_arr) AS upsell,
        SUM(CASE WHEN cm.current_arr < cm.prev_arr THEN cm.prev_arr - cm.current_arr ELSE 0 END) AS downsell,

        -- Total ARR
        SUM(cm.current_arr) AS current_arr_total,
        SUM(cm.prev_arr) AS prev_arr_total
    FROM customer_movement cm
    GROUP BY 1, 2
),

final_metrics AS (
    SELECT
        rm.payment_month,
        rm.fiscal_year,
        rm.customer_churn,
        rm.downsell,
        rm.product_churn,
        -- GRR: [(Starting Revenue - Churn - Product Churn - Downsell) / Starting Revenue] * 100
        ROUND(
            (rm.prev_arr_total - rm.customer_churn - rm.product_churn - rm.downsell) 
            / NULLIF(rm.prev_arr_total, 0) * 100, 
            2
        ) AS grr,
        rm.upsell,
        cs.cross_sell_revenue AS crosssell,
        -- NRR: [(Starting + Upsell + Cross-sell - Churn - Downsell) / Starting] * 100
        ROUND(
            (rm.prev_arr_total + rm.upsell + cs.cross_sell_revenue - rm.customer_churn - rm.downsell) 
            / NULLIF(rm.prev_arr_total, 0) * 100, 
            2
        ) AS nrr,
        rm.new_logos,
        rm.current_arr_total,
    FROM revenue_movement rm
    LEFT JOIN cross_sell_revenue cs ON rm.payment_month = cs.payment_month
)

SELECT * FROM
    final_metrics
ORDER BY payment_month
        );
      
  