-- Q1: Sao Paulo alone accounts for 42% of orders; the top 3 states (SP, RJ, MG) concentrate ~67% of orders.
-- Demand is heavily concentrated in the southeast.
-- All 99,441 orders match a customer (no rows lost in the join).

SELECT
    c.customer_state,
    COUNT(*) AS order_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM orders), 1) AS pct_of_orders
FROM orders AS o 
INNER JOIN customers AS c 
    ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY order_count DESC
LIMIT 10;