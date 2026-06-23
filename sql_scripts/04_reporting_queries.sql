/* 
   04_reporting_queries.sql
   The three business questions, answered from the KPI summary.
  */

USE OlistEcommerce;
GO

-- REPORT 1: Total sales per product category (all-time)
SELECT
    dimension_value AS product_category,
    SUM(metric_value) AS total_sales
FROM gold.kpi_summary
WHERE kpi_type = 'sales_per_category'
GROUP BY dimension_value
ORDER BY total_sales DESC;

-- REPORT 2: Average delivery time per seller (all-time)
SELECT
    dimension_value AS seller_id,
    AVG(metric_value) AS avg_delivery_days
FROM gold.kpi_summary
WHERE kpi_type = 'avg_delivery_per_seller'
GROUP BY dimension_value
ORDER BY avg_delivery_days DESC;

-- REPORT 3: Number of orders per customer state (all-time)
SELECT
    dimension_value AS customer_state,
    SUM(metric_value) AS total_orders
FROM gold.kpi_summary
WHERE kpi_type = 'orders_per_state'
GROUP BY dimension_value
ORDER BY total_orders DESC;

-- quick check: how many rows landed under each KPI
SELECT kpi_type, COUNT(*) AS row_count
FROM gold.kpi_summary
GROUP BY kpi_type;
GO
