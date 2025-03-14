-- WITH revenues AS (
--     SELECT 
--         customer_id,
--         payment_month,
--         SUM(revenue) AS total_revenue,
--         SUM(CASE WHEN revenue_type = 1 THEN revenue ELSE 0 END) AS recurring_revenue,
--         SUM(CASE WHEN revenue_type = 0 THEN revenue ELSE 0 END) AS reoccuring_revenue
--     FROM 
--         PROJECT_DB.PROJECT_SCHEMA_stage.stg_transactions
--     GROUP BY 
--         customer_id, payment_month
-- ),
-- monthly_revenue AS (
--     SELECT
--         customer_id,
--         payment_month,
--         total_revenue,
--         recurring_revenue,
--         reoccuring_revenue,
--         recurring_revenue - reoccuring_revenue AS grr
--     FROM
--         revenues
-- ),
-- nrr_calculation AS (
--     SELECT
--         customer_id,
--         payment_month,
--         recurring_revenue,
--         LAG(recurring_revenue) OVER (PARTITION BY customer_id ORDER BY payment_month) AS previous_recurring_revenue
--     FROM
--         monthly_revenue
-- ),
-- grr_with_downsell AS (
--     SELECT
--         customer_id,
--         payment_month,
--         total_revenue,
--         recurring_revenue,
--         reoccuring_revenue,
--         grr,
--         CASE 
--             WHEN previous_recurring_revenue > recurring_revenue THEN previous_recurring_revenue - recurring_revenue
--             ELSE 0
--         END AS downsell
--     FROM
--         nrr_calculation
--     JOIN
--         monthly_revenue USING (customer_id, payment_month)
-- )
-- SELECT
--     customer_id,
--     payment_month,
--     total_revenue,
--     recurring_revenue,
--     reoccuring_revenue,
--     grr,
--     downsell,
--     CASE 
--         WHEN previous_recurring_revenue = 0 THEN 0
--         ELSE (recurring_revenue / previous_recurring_revenue) * 100
--     END AS nrr
-- FROM
--     grr_with_downsell
-- ORDER BY
--     customer_id, payment_month



WITH revenues AS (
    SELECT 
        customer_id,
        payment_month,
        SUM(revenue) AS total_revenue,
        SUM(CASE WHEN revenue_type = 1 THEN revenue ELSE 0 END) AS recurring_revenue,
        SUM(CASE WHEN revenue_type = 0 THEN revenue ELSE 0 END) AS reoccuring_revenue
    FROM 
        PROJECT_DB.PROJECT_SCHEMA_stage.stg_transactions
    GROUP BY 
        customer_id, payment_month
),
monthly_revenue AS (
    SELECT
        customer_id,
        payment_month,
        total_revenue,
        recurring_revenue,
        reoccuring_revenue,
        recurring_revenue - reoccuring_revenue AS diff
    FROM
        revenues
),
nrr_calculation AS (
    SELECT
        customer_id,
        payment_month,
        recurring_revenue,
        LAG(recurring_revenue) OVER (PARTITION BY customer_id ORDER BY payment_month) AS previous_recurring_revenue
    FROM
        monthly_revenue
),
grr_with_downsell AS (
    SELECT
        n.customer_id,
        n.payment_month,
        m.total_revenue,
        n.recurring_revenue,
        m.reoccuring_revenue,
        m.diff,
        n.previous_recurring_revenue,
        CASE 
            WHEN n.previous_recurring_revenue > n.recurring_revenue THEN n.previous_recurring_revenue - n.recurring_revenue
            ELSE 0
        END AS downsell
    FROM
        nrr_calculation n
    JOIN
        monthly_revenue m
    ON
        n.customer_id = m.customer_id AND n.payment_month = m.payment_month
)
SELECT
    customer_id,
    payment_month,
    total_revenue,
    recurring_revenue,
    reoccuring_revenue,
    (diff-downsell) AS grr,
    CASE 
        WHEN previous_recurring_revenue = 0 THEN 0
        ELSE (recurring_revenue / previous_recurring_revenue) * 100
    END AS nrr
FROM
    grr_with_downsell
ORDER BY
    customer_id, payment_month