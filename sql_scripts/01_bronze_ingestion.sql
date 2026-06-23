/* 
   01_bronze_ingestion.sql
   Creates the raw bronze tables. The CSV data is loaded into
   these tables using the SSMS Import Wizard (right-click the
   database > Tasks > Import Flat File), not by script.

   After importing, two small fixes are done on bronze.orders:
     - fill the year / month / day columns from the timestamp
     - turn the '1899-12-30' placeholder dates into NULL
       (empty date cells from Excel came in as 1899-12-30)
    */

USE OlistEcommerce;
GO

-- orders is the only partitioned table (on order_purchase_timestamp)
CREATE TABLE bronze.orders (
    order_id                       VARCHAR(50),
    customer_id                    VARCHAR(50),
    order_status                   VARCHAR(50),
    order_purchase_timestamp       DATETIME,
    order_approved_at              DATETIME,
    order_delivered_carrier_date   DATETIME,
    order_delivered_customer_date  DATETIME,
    order_estimated_delivery_date  DATETIME,
    [year]  INT,
    [month] INT,
    [day]   INT
)
ON ps_OrderDate (order_purchase_timestamp);
GO

CREATE TABLE bronze.order_items (
    order_id            VARCHAR(50),
    order_item_id       INT,
    product_id          VARCHAR(50),
    seller_id           VARCHAR(50),
    shipping_limit_date DATETIME,
    price               DECIMAL(10,2),
    freight_value       DECIMAL(10,2)
);
GO

CREATE TABLE bronze.customers (
    customer_id              VARCHAR(50),
    customer_unique_id       VARCHAR(50),
    customer_zip_code_prefix VARCHAR(50),
    customer_city            VARCHAR(100),
    customer_state           VARCHAR(50)
);
GO

CREATE TABLE bronze.products (
    product_id                 VARCHAR(50),
    product_category_name      VARCHAR(100),
    product_name_lenght        INT,
    product_description_lenght INT,
    product_photos_qty         INT,
    product_weight_g           INT,
    product_length_cm          INT,
    product_height_cm          INT,
    product_width_cm           INT
);
GO

CREATE TABLE bronze.sellers (
    seller_id              VARCHAR(50),
    seller_zip_code_prefix VARCHAR(50),
    seller_city            VARCHAR(100),
    seller_state           VARCHAR(50)
);
GO

CREATE TABLE bronze.order_payments (
    order_id             VARCHAR(50),
    payment_sequential   INT,
    payment_type         VARCHAR(50),
    payment_installments INT,
    payment_value        DECIMAL(10,2)
);
GO

CREATE TABLE bronze.order_reviews (
    review_id               VARCHAR(50),
    order_id                VARCHAR(50),
    review_score            INT,
    review_comment_title    VARCHAR(200),
    review_comment_message  VARCHAR(8000),
    review_creation_date    DATETIME,
    review_answer_timestamp DATETIME
);
GO

/* ---- After loading the CSVs with the Import Wizard, run the fixes below  */

-- fill the partition columns from the purchase date
UPDATE bronze.orders
SET [year]  = YEAR(order_purchase_timestamp),
    [month] = MONTH(order_purchase_timestamp),
    [day]   = DAY(order_purchase_timestamp);

-- empty date cells came in from Excel as '1899-12-30'; set them back to NULL
UPDATE bronze.orders SET order_approved_at = NULL
WHERE order_approved_at = '1899-12-30 00:00:00.000';

UPDATE bronze.orders SET order_delivered_carrier_date = NULL
WHERE order_delivered_carrier_date = '1899-12-30 00:00:00.000';

UPDATE bronze.orders SET order_delivered_customer_date = NULL
WHERE order_delivered_customer_date = '1899-12-30 00:00:00.000';
GO
