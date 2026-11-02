-- Q1: 97% of orders were delivered; ~1.2% failed (canceled or unavailable); the rest still in progress.

SELECT 
    order_status, 
    COUNT(*) AS order_count, 
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM orders), 1) AS pct_of_orders
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;


-- Q2: Orders grew from ~800 (Jan 2017) to ~7300 (Jan 2018). 
-- November 2017 was the busiest month with 7544 orders placed.
-- Late 2016 and Sep - Oct 2018 have very few orders, likely incomplete data; excluded from the trend.

SELECT 
    date_trunc('month', order_purchase_timestamp)::DATE AS order_month,
    COUNT(order_id) AS order_count
FROM orders
GROUP BY order_month
ORDER BY order_month ASC;


-- Q3: Median delivery time is 10 days. The average (12.5) is higher because a small group
-- of very slow orders (up to 210 days) pulls it up. Typical delivery time for most customers is ~10 days.
-- Only delivered orders with a recorded delivery date were considered.

WITH delivered_orders AS (
    SELECT
        order_id,
        date_diff('day', order_purchase_timestamp, order_delivered_customer_date) AS days_to_deliver
    FROM orders
    WHERE order_status = 'delivered'
        AND order_delivered_customer_date IS NOT NULL
)
SELECT
    ROUND(AVG(days_to_deliver), 1) AS avg_days_to_deliver,
    ROUND(MEDIAN(days_to_deliver), 1) AS median_days_to_deliver,
    MAX(days_to_deliver) AS slowest_order_to_deliver
FROM delivered_orders;