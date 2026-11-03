#!/bin/bash
# Rebuilds the Olist DuckDB database from scratch

set -e # stop immediately if any command fails

# 1. Download and unzip the dataset
if [ ! -d "data/olist" ]; then
    kaggle datasets download -d olistbr/brazilian-ecommerce -p data/olist --unzip
fi

# 2. Load tables into olist.duckdb
duckdb olist.duckdb <<'SQL'
CREATE OR REPLACE TABLE orders AS 
SELECT * FROM read_csv_auto('data/olist/olist_orders_dataset.csv');

CREATE OR REPLACE TABLE payments AS
SELECT * FROM read_csv_auto('data/olist/olist_order_payments_dataset.csv');

CREATE OR REPLACE TABLE customers AS
SELECT * FROM read_csv_auto('data/olist/olist_customers_dataset.csv');

CREATE OR REPLACE TABLE order_items AS
SELECT * FROM read_csv_auto('data/olist/olist_order_items_dataset.csv');

CREATE OR REPLACE TABLE products AS
SELECT * FROM read_csv_auto('data/olist/olist_products_dataset.csv');

CREATE OR REPLACE TABLE category_translation AS
SELECT * FROM read_csv_auto('data/olist/product_category_name_translation.csv');

CREATE OR REPLACE TABLE reviews AS
SELECT * FROM read_csv_auto('data/olist/olist_order_reviews_dataset.csv');


-- 3. Print row counts to confirm it worked
SELECT
    (SELECT COUNT(*) FROM orders) AS orders,
    (SELECT COUNT(*) FROM payments) AS payments,
    (SELECT COUNT(*) FROM customers) AS customers,
    (SELECT COUNT(*) FROM order_items) AS order_items,
    (SELECT COUNT(*) FROM products) AS products,
    (SELECT COUNT(*) FROM category_translation) AS category_translation,
    (SELECT COUNT(*) FROM reviews) AS reviews
;
SQL