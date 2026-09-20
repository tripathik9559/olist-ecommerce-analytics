-- ============================================================
-- OLIST E-COMMERCE ANALYTICS — DATABASE SCHEMA
-- File: 01_schema.sql
-- ============================================================
-- INSTRUCTIONS:
--   Run this file FIRST before importing any data.
--   Then import CSVs using MySQL Workbench's Table Data Import Wizard.
--   Import ORDER matters (foreign keys):
--     1. customers
--     2. products
--     3. category_translation
--     4. orders
--     5. order_items
-- ============================================================

-- Create and select the database
CREATE DATABASE IF NOT EXISTS olist_analytics;
USE olist_analytics;


-- ============================================================
-- TABLE 1: customers
-- One row per customer_id.
-- IMPORTANT: Same person can have multiple customer_ids.
-- Use customer_unique_id to identify a unique human.
-- ============================================================
CREATE TABLE IF NOT EXISTS customers (
    customer_id              VARCHAR(50)  NOT NULL,
    customer_unique_id       VARCHAR(50)  NOT NULL,
    customer_zip_code_prefix VARCHAR(10),
    customer_city            VARCHAR(100),
    customer_state           CHAR(2),
    PRIMARY KEY (customer_id)
);


-- ============================================================
-- TABLE 2: products
-- One row per product.
-- product_category_name is in Portuguese — needs translation.
-- ============================================================
CREATE TABLE IF NOT EXISTS products (
    product_id                  VARCHAR(50)  NOT NULL,
    product_category_name       VARCHAR(100),
    product_name_length         INT,
    product_description_length  INT,
    product_photos_qty          INT,
    product_weight_g            INT,
    product_length_cm           INT,
    product_height_cm           INT,
    product_width_cm            INT,
    PRIMARY KEY (product_id)
);


-- ============================================================
-- TABLE 3: category_translation
-- Maps Portuguese category names to English.
-- Used with a LEFT JOIN so no products are lost if untranslated.
-- ============================================================
CREATE TABLE IF NOT EXISTS category_translation (
    product_category_name          VARCHAR(100) NOT NULL,
    product_category_name_english  VARCHAR(100),
    PRIMARY KEY (product_category_name)
);


-- ============================================================
-- TABLE 4: orders
-- One row per order.
-- Contains the order status and all relevant date timestamps.
-- We will mostly filter WHERE order_status = 'delivered'.
-- ============================================================
CREATE TABLE IF NOT EXISTS orders (
    order_id                        VARCHAR(50)  NOT NULL,
    customer_id                     VARCHAR(50),
    order_status                    VARCHAR(20),
    order_purchase_timestamp        DATETIME,
    order_approved_at               DATETIME,
    order_delivered_carrier_date    DATETIME,
    order_delivered_customer_date   DATETIME,
    order_estimated_delivery_date   DATETIME,
    PRIMARY KEY (order_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);


-- ============================================================
-- TABLE 5: order_items
-- One row per item within an order.
-- An order can have multiple items (multiple rows per order_id).
-- Revenue = price + freight_value per row.
-- ============================================================
CREATE TABLE IF NOT EXISTS order_items (
    order_id             VARCHAR(50)   NOT NULL,
    order_item_id        INT           NOT NULL,   -- item number within the order
    product_id           VARCHAR(50),
    seller_id            VARCHAR(50),
    shipping_limit_date  DATETIME,
    price                DECIMAL(10,2),
    freight_value        DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);


-- ============================================================
-- VERIFICATION QUERIES
-- Run these after importing data to check row counts.
-- ============================================================

-- Expected approximate counts for Olist dataset:
--   customers      → ~99,000 rows
--   products       → ~32,000 rows
--   category_trans → ~71 rows
--   orders         → ~99,000 rows
--   order_items    → ~112,000 rows

SELECT 'customers'          AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'products',                         COUNT(*) FROM products
UNION ALL
SELECT 'category_translation',             COUNT(*) FROM category_translation
UNION ALL
SELECT 'orders',                           COUNT(*) FROM orders
UNION ALL
SELECT 'order_items',                      COUNT(*) FROM order_items;
