-- Q1: February 2017 recorded a revenue of R$234,223.40, which is a ~110% increase compared to January 2017 (R$111,798.36).
-- This jump can be attributed to early ramp-up, when the business started to grow from a very small base.
-- Excluding the early ramp-up, the biggest jump was November 2017 (R$987,765.37), 
-- with a ~52% increase, driven by Black Friday.
-- Late 2016 was excluded due to incomplete data and a gap in between October and December.
-- September and October 2018 were also excluded due to incomplete data.
-- Due to late 2016 being excluded, the previous month data for January 2017 is NULL.
-- Revenue is the sum of item prices from delivered orders (freight excluded).

WITH delivered_orders AS (
    SELECT
        order_id,
        date_trunc('month', order_purchase_timestamp)::DATE AS order_month
    FROM orders
    WHERE order_status = 'delivered'
        AND order_purchase_timestamp >= DATE '2017-01-01'
        AND order_purchase_timestamp < DATE '2018-09-01'
),
monthly_revenue AS (
    SELECT
        dlv.order_month AS order_month,
        SUM(oi.price) AS revenue
    FROM delivered_orders AS dlv
    INNER JOIN order_items AS oi 
        ON dlv.order_id = oi.order_id
    GROUP BY dlv.order_month
),
revenue_with_prev AS (
    SELECT
        mr.order_month AS order_month,
        mr.revenue AS revenue,
        LAG(mr.revenue) OVER (ORDER BY mr.order_month) AS prev_revenue
    FROM monthly_revenue AS mr
)
SELECT
    rwp.order_month,
    ROUND(rwp.revenue, 2) AS revenue,
    ROUND(rwp.prev_revenue, 2) AS prev_month_revenue,
    ROUND((rwp.revenue - rwp.prev_revenue) / 
    (rwp.prev_revenue) * 100.0, 1) AS pct_change
FROM revenue_with_prev AS rwp
ORDER BY rwp.order_month;




