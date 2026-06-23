/* 
   03_gold_analytics.sql
   Builds the gold layer on top of the clean silver tables:
     1. cumulative sales per customer  (running total)
     2. rolling average delivery time per category (last 3 orders)
     3. a KPI summary table feeding the final reports
    */

USE OlistEcommerce;
GO

-- ---------- 1. Cumulative sales per customer ----------
CREATE TABLE gold.cumulative_sales_per_customer (
    customer_id              VARCHAR(50),
    order_id                 VARCHAR(50),
    order_purchase_timestamp DATETIME,
    total_price              DECIMAL(10,2),
    cumulative_sales         DECIMAL(10,2),
    [year]  INT,
    [month] INT,
    [day]   INT
)
ON ps_OrderDate (order_purchase_timestamp);
GO

INSERT INTO gold.cumulative_sales_per_customer
SELECT
    customer_id,
    order_id,
    order_purchase_timestamp,
    total_price,
    SUM(total_price) OVER (
        PARTITION BY customer_id
        ORDER BY order_purchase_timestamp
    ) AS cumulative_sales,
    [year], [month], [day]
FROM silver.orders;
GO

-- ---------- 2. Rolling average delivery time per category ----------
CREATE TABLE gold.rolling_avg_delivery_time (
    product_category_name     VARCHAR(100),
    order_id                  VARCHAR(50),
    order_purchase_timestamp  DATETIME,
    delivery_time_days        INT,
    rolling_avg_delivery_time FLOAT,
    [year]  INT,
    [month] INT,
    [day]   INT
)
ON ps_OrderDate (order_purchase_timestamp);
GO

INSERT INTO gold.rolling_avg_delivery_time
SELECT
    p.product_category_name,
    o.order_id,
    o.order_purchase_timestamp,
    o.delivery_time_days,
    AVG(CAST(o.delivery_time_days AS FLOAT)) OVER (
        PARTITION BY p.product_category_name
        ORDER BY o.order_purchase_timestamp
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_avg_delivery_time,
    o.[year], o.[month], o.[day]
FROM silver.orders o
INNER JOIN silver.products p
    ON o.product_id = p.product_id;
GO

-- ---------- 3. KPI summary table ----------
CREATE TABLE gold.kpi_summary (
    kpi_type        VARCHAR(50),
    dimension_value VARCHAR(100),
    metric_value    DECIMAL(18,2),
    [year]  INT,
    [month] INT,
    [day]   INT,
    report_date DATETIME            -- first day of the month, used for partitioning
)
ON ps_OrderDate (report_date);
GO

-- KPI 1: total sales per product category, per month
INSERT INTO gold.kpi_summary
SELECT
    'sales_per_category',
    p.product_category_name,
    SUM(o.total_price),
    o.[year], o.[month], 1,
    DATEFROMPARTS(o.[year], o.[month], 1)
FROM silver.orders o
INNER JOIN silver.products p
    ON o.product_id = p.product_id
GROUP BY p.product_category_name, o.[year], o.[month];

-- KPI 2: average delivery time per seller, per month
INSERT INTO gold.kpi_summary
SELECT
    'avg_delivery_per_seller',
    o.seller_id,
    AVG(CAST(o.delivery_time_days AS DECIMAL(18,2))),
    o.[year], o.[month], 1,
    DATEFROMPARTS(o.[year], o.[month], 1)
FROM silver.orders o
GROUP BY o.seller_id, o.[year], o.[month];

-- KPI 3: number of orders per customer state, per month
-- COUNT(DISTINCT order_id) because silver.orders is one row per item
INSERT INTO gold.kpi_summary
SELECT
    'orders_per_state',
    c.customer_state,
    COUNT(DISTINCT o.order_id),
    o.[year], o.[month], 1,
    DATEFROMPARTS(o.[year], o.[month], 1)
FROM silver.orders o
INNER JOIN silver.customers c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_state, o.[year], o.[month];
GO
