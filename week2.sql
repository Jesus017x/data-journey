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

-- Q2: Health beauty, watches gifts and bed bath tables are the top 3 product categories by revenue,
-- all exceeding R$1,000,000. Overall, top 10 categories make up ~62% of delivered revenue.
-- Revenue is the sum of items sold from orders that were delivered.
-- Freight value was excluded from the revenue due to shipping costs being passed to the client.
-- Products with no category (~1.3% of items) are labeled 'unknown'.
-- Untranslated categories kept their Portuguese name. Neither appears in the top 10.

SELECT 
    COALESCE(ct.product_category_name_english, p.product_category_name, 'unknown') AS category_name,
    ROUND(SUM(oi.price), 2) AS revenue,
    ROUND(100.0 * SUM(oi.price) / SUM(SUM(oi.price)) OVER (), 1) AS pct_of_revenue
FROM order_items AS oi
LEFT JOIN products AS p 
    ON oi.product_id = p.product_id
LEFT JOIN category_translation AS ct 
    ON p.product_category_name = ct.product_category_name
INNER JOIN orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY category_name
ORDER BY revenue DESC
LIMIT 10;