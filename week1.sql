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


-- Q4: Share of orders delivered after the estimated delivery date is ~6.8%.
-- "Late" = delivered on a later calendar day than estimated.
-- (Same day delivery counts as on time).
-- Only delivered orders with both dates recorded were taken into account.

WITH delivered_orders AS (
    SELECT
        order_id,
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
    ROUND(100.0 * AVG(is_late), 1) AS pct_late_deliveries
FROM delivered_orders;


-- Q5: Most common payment_type is credit_card with over 76000 instances, which is ~74% of all payment records.
-- The average payment_value for credit_card is R$163.32 which is the highest amongst all payment_type.
-- Vouchers had the lowest average payment value (R$65.70). 
-- not_defined had R$0.0 recorded across 3 payments, likely to be bad data.
-- Vouchers had ~5800 payments across ~3900 orders, which indicates that clients split orders across multiple vouchers.

SELECT
    payment_type,
    COUNT(DISTINCT order_id) AS order_count,
    COUNT(*) AS payment_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM payments), 1) AS pct_of_payments,
    ROUND(AVG(payment_value), 2) AS avg_payment_value
FROM payments
GROUP BY payment_type
ORDER BY payment_count DESC;
