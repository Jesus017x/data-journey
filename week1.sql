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