/* 
   02_silver_transformation.sql
   Cleans the bronze tables into a tidy silver layer:
     - strips the stray double-quote characters from text columns
     - keeps only delivered orders (delivery time needs a
       delivery date)
     - adds the calculated columns: total_price, profit_margin,
       delivery_time_days
     - labels products with no category as 'unknown'
    */

USE OlistEcommerce;
GO

-- ---------- 1. silver.orders (one row per order item) ----------
CREATE TABLE silver.orders (
    order_id                      VARCHAR(50),
    customer_id                   VARCHAR(50),
    product_id                    VARCHAR(50),
    seller_id                     VARCHAR(50),
    order_status                  VARCHAR(50),
    order_purchase_timestamp      DATETIME,
    order_delivered_customer_date DATETIME,
    price                         DECIMAL(10,2),
    freight_value                 DECIMAL(10,2),
    total_price                   DECIMAL(10,2),
    profit_margin                 DECIMAL(10,2),
    delivery_time_days            INT,
    [year]  INT,
    [month] INT,
    [day]   INT
);
GO

INSERT INTO silver.orders (
    order_id, customer_id, product_id, seller_id, order_status,
    order_purchase_timestamp, order_delivered_customer_date,
    price, freight_value, total_price, profit_margin, delivery_time_days,
    [year], [month], [day]
)
SELECT
    REPLACE(o.order_id, '"', ''),
    REPLACE(o.customer_id, '"', ''),
    REPLACE(oi.product_id, '"', ''),
    REPLACE(oi.seller_id, '"', ''),
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    oi.price,
    oi.freight_value,
    oi.price + oi.freight_value AS total_price,
    oi.price - oi.freight_value AS profit_margin,
    DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date) AS delivery_time_days,
    o.[year],
    o.[month],
    o.[day]
FROM bronze.orders o
INNER JOIN bronze.order_items oi
    ON REPLACE(o.order_id, '"', '') = REPLACE(oi.order_id, '"', '')
WHERE o.order_delivered_customer_date IS NOT NULL;
GO

-- ---------- 2. silver.customers ----------
CREATE TABLE silver.customers (
    customer_id              VARCHAR(50),
    customer_unique_id       VARCHAR(50),
    customer_zip_code_prefix VARCHAR(50),
    customer_city            VARCHAR(100),
    customer_state           VARCHAR(50)
);
GO

INSERT INTO silver.customers
SELECT
    REPLACE(customer_id, '"', ''),
    REPLACE(customer_unique_id, '"', ''),
    REPLACE(customer_zip_code_prefix, '"', ''),
    customer_city,
    customer_state
FROM bronze.customers;
GO

-- ---------- 3. silver.sellers ----------
CREATE TABLE silver.sellers (
    seller_id              VARCHAR(50),
    seller_zip_code_prefix VARCHAR(50),
    seller_city            VARCHAR(100),
    seller_state           VARCHAR(50)
);
GO

INSERT INTO silver.sellers
SELECT
    REPLACE(seller_id, '"', ''),
    REPLACE(seller_zip_code_prefix, '"', ''),
    seller_city,
    seller_state
FROM bronze.sellers;
GO

-- ---------- 4. silver.products ----------
-- products with no category are labeled 'unknown' right here
CREATE TABLE silver.products (
    product_id            VARCHAR(50),
    product_category_name VARCHAR(100)
);
GO

INSERT INTO silver.products
SELECT
    REPLACE(product_id, '"', ''),
    CASE WHEN product_category_name IS NULL OR product_category_name = ''
         THEN 'unknown'
         ELSE product_category_name
    END
FROM bronze.products;
GO

-- ---------- 5. silver.order_payments (one row per order) ----------
CREATE TABLE silver.order_payments (
    order_id            VARCHAR(50),
    payment_count       INT,
    total_payment_value DECIMAL(10,2)
);
GO

INSERT INTO silver.order_payments
SELECT
    REPLACE(order_id, '"', ''),
    COUNT(*) AS payment_count,
    SUM(payment_value) AS total_payment_value
FROM bronze.order_payments
GROUP BY REPLACE(order_id, '"', '');
GO

-- ---------- 6. silver.order_reviews ----------
CREATE TABLE silver.order_reviews (
    review_id    VARCHAR(50),
    order_id     VARCHAR(50),
    review_score INT
);
GO

INSERT INTO silver.order_reviews
SELECT
    REPLACE(review_id, '"', ''),
    REPLACE(order_id, '"', ''),
    review_score
FROM bronze.order_reviews;
GO
