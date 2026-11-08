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


-- Q3: Maranhao is the state with the highest late delivery rate with ~17% of its deliveries being late,
-- which is about 2.5x the national rate (~6.8%).
-- Ceara (~14%), Bahia (~12%), Rio de Janeiro (~12%) and Para (~11%) close the top 5.
-- The states in the top 5 (aside from Rio de Janeiro) are in the North/Northeast with a lower order volume
-- and far from where most orders are concentrated (South/Southeast). 
-- States with fewer than 500 orders delivered were ignored due to small sample sizes producing unreliable rates.

WITH orders_delivered AS (
    SELECT
        order_id,
        customer_id,
        CASE 
            WHEN order_delivered_customer_date::DATE > order_estimated_delivery_date::DATE THEN 1
            ELSE 0
        END AS is_late
    FROM orders 
    WHERE order_status = 'delivered'
        AND order_delivered_customer_date IS NOT NULL
        AND order_estimated_delivery_date IS NOT NULL
)
SELECT
    c.customer_state,
    COUNT(*) AS delivered_orders,
    ROUND(100.0 * AVG(od.is_late), 1) AS late_delivery_rate
FROM orders_delivered AS od
LEFT JOIN customers AS c
    ON od.customer_id = c.customer_id
GROUP BY c.customer_state
HAVING COUNT(*) >= 500
ORDER BY late_delivery_rate DESC;


-- Q4: Late deliveries (n = 6381) average 2.3 vs 4.3 for on-time deliveries (n = 89443).
-- This is 2 points lower on a 1-5 scale.
-- Review scores were averaged per order (verified: 1 row per order). 
-- Delivered orders without a review were excluded (INNER join).
-- An order is considered as "late" if it was delivered after the estimated delivery date.
-- Same day delivery or before, are considered as orders being delivered "on time".
-- On-time deliveries get a 1-star review score on ~7% of delivered orders; late deliveries on ~54% of delivered orders.

WITH order_reviews AS (
    SELECT 
        order_id,
        AVG(review_score) AS review_score
    FROM reviews
    GROUP BY order_id
),
orders_delivered AS (
    SELECT
        o.order_id,
        CASE
            WHEN o.order_delivered_customer_date::DATE <= o.order_estimated_delivery_date::DATE THEN orv.review_score
            ELSE NULL
        END AS on_time_delivery_rscore,
        CASE 
            WHEN o.order_delivered_customer_date::DATE > o.order_estimated_delivery_date::DATE THEN orv.review_score
            ELSE NULL
        END AS late_delivery_rscore,
        CASE
            WHEN o.order_delivered_customer_date::DATE <= o.order_estimated_delivery_date::DATE 
            AND orv.review_score <= 1 THEN orv.review_score
            ELSE NULL
        END AS on_time_one_star_rscore,
        CASE
            WHEN o.order_delivered_customer_date::DATE > o.order_estimated_delivery_date::DATE 
            AND orv.review_score <= 1 THEN orv.review_score
            ELSE NULL
        END AS late_one_star_rscore
    FROM orders AS o
    INNER JOIN order_reviews AS orv 
        ON o.order_id = orv.order_id
    WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
)
SELECT
    COUNT(on_time_delivery_rscore) AS on_time_orders,
    COUNT(late_delivery_rscore) AS late_orders,
    ROUND(AVG(on_time_delivery_rscore), 1) AS avg_on_time,
    ROUND(AVG(late_delivery_rscore), 1) AS avg_late,
    ROUND(100.0 * COUNT(on_time_one_star_rscore) / COUNT(on_time_delivery_rscore), 1) AS pct_on_time_one_star,
    ROUND(100.0 * COUNT(late_one_star_rscore) / COUNT(late_delivery_rscore), 1) AS pct_late_one_star
FROM orders_delivered;


-- Q5: ~0.8% (n = 768) of all orders (n = 99441) have no reviews at all. 646 of the 768 (84%) are delivered orders.
-- This matches the 646 orders that were dropped in Q4.
-- Canceled orders lack a review 3.2% of the time vs ~0.7% for delivered.
-- (created shows 40%, but n = 5, too small to be meaningful.)
-- A 'no review order' is an order where no review record was registered.

WITH reviewed_orders AS (
    SELECT DISTINCT order_id
    FROM reviews
)
SELECT 
    o.order_status,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN r.order_id IS NULL THEN 1 ELSE 0 END) AS orders_without_reviews,
    ROUND(100.0 * AVG(CASE WHEN r.order_id IS NULL THEN 1 ELSE 0 END), 1) AS pct_without_reviews
FROM orders AS o
LEFT JOIN reviewed_orders AS r 
    ON o.order_id = r.order_id
GROUP BY o.order_status
ORDER BY total_orders DESC;


-- Reflection: Why joining payments to order_items gives the wrong revenue?
-- Payments has 1 row per payment and order_items 1 row per item, so both are multiple per order.
-- Joining them on order_id repeats each payment once per item in its order
-- (and payments can be split, so we could have 2 payments * 3 items = 6 rows)
-- Measured: the joined total was ~R$4.3M (~26.9%) higher than the real payment total.
-- Fix: aggregate each table to one row per order first, then join.

SELECT ROUND(100.0 * (
    (SELECT SUM(pay.payment_value) FROM payments AS pay
    INNER JOIN order_items AS oi 
    ON pay.order_id = oi.order_id)
    -
    (SELECT SUM(payment_value) FROM payments)) 
    / 
    (SELECT SUM(payment_value) FROM payments), 1) AS pct_inflated;