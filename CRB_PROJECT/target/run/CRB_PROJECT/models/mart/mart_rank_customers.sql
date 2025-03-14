
  
    

        create or replace transient table PROJECT_DB.PROJECT_SCHEMA_mart.mart_rank_customers
         as
        (WITH customers AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.company
    FROM PROJECT_DB.PROJECT_SCHEMA_stage.stg_customers c
),
total_revenue AS (
    SELECT
        t.customer_id,
        SUM(t.revenue) AS total_revenue,
        RANK() OVER(ORDER BY SUM(t.revenue) DESC) AS revenue_rank
    FROM PROJECT_DB.PROJECT_SCHEMA_stage.stg_transactions t
    JOIN customers c ON t.customer_id = c.customer_id
    GROUP BY t.customer_id
)

SELECT * 
FROM total_revenue
ORDER BY revenue_rank
        );
      
  