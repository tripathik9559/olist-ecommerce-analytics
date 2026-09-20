-- ============================================================
-- OLIST E-COMMERCE ANALYTICS — BUSINESS QUERIES
-- File: 02_queries.sql
-- ============================================================
-- Run AFTER 01_schema.sql and data import.
-- All queries filter WHERE order_status = 'delivered'
-- because only delivered orders count as completed revenue.
-- ============================================================

USE olist_analytics;


-- ============================================================
-- QUERY 1: TOTAL ORDERS
-- ============================================================
-- WHAT IT DOES:
--   Counts how many unique orders were successfully delivered.
-- WHY COUNT DISTINCT:
--   order_items has MULTIPLE rows per order (one per item in the order).
--   Without DISTINCT, an order with 3 items gets counted 3 times.
-- EXPECTED OUTPUT: ~96,000 - 97,000 orders
-- ============================================================

SELECT 
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
WHERE order_status = 'delivered';


-- ============================================================
-- QUERY 2: TOTAL REVENUE
-- ============================================================
-- WHAT IT DOES:
--   Sums price + freight_value for all delivered order items.
-- WHY price + freight_value:
--   This is the total amount the customer paid (product cost + shipping).
-- WHY JOIN:
--   Revenue data is in order_items; order status is in orders.
--   We JOIN to apply the 'delivered' filter.
-- EXPECTED OUTPUT: ~R$16 - R$17 million
-- ============================================================

SELECT 
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered';


-- ============================================================
-- QUERY 3: AVERAGE ORDER VALUE (AOV)
-- ============================================================
-- WHAT IT DOES:
--   Calculates average revenue per order.
-- FORMULA: Total Revenue / Total Orders
-- WHY NOT AVG(price):
--   AVG(price) gives the average price of ONE ITEM — not one order.
--   Some orders have multiple items. We need total order value / number of orders.
-- EXPECTED OUTPUT: ~R$155 - R$170
-- ============================================================

SELECT 
    ROUND(
        SUM(oi.price + oi.freight_value) / COUNT(DISTINCT oi.order_id),
        2
    ) AS avg_order_value
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered';


-- ============================================================
-- QUERY 4: MONTHLY REVENUE TREND
-- ============================================================
-- WHAT IT DOES:
--   Shows total revenue and order count for each month.
--   Useful for spotting seasonality, growth, or drops.
-- DATE_FORMAT(col, '%Y-%m'):
--   Converts a DATETIME like '2017-11-15 08:30:00' to just '2017-11'.
--   This groups all orders from the same month together.
-- EXPECTED: Peak in Nov 2017 (Black Friday), growth from mid-2016 to late-2017
-- ============================================================

SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    ROUND(SUM(oi.price + oi.freight_value), 2)       AS monthly_revenue,
    COUNT(DISTINCT o.order_id)                        AS monthly_orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY month ASC;


-- ============================================================
-- QUERY 5: TOP 10 PRODUCT CATEGORIES BY REVENUE
-- ============================================================
-- WHAT IT DOES:
--   Finds which product categories generate the most revenue.
-- 3-TABLE JOIN:
--   order_items → products (to get category name)
--   products → category_translation (to get English name)
-- LEFT JOIN on category_translation:
--   Some products may NOT have an English translation.
--   LEFT JOIN keeps them; INNER JOIN would lose them.
-- COALESCE(A, B):
--   Returns A if A is not NULL, otherwise returns B.
--   Here: use English name if available, else keep Portuguese name.
-- EXPECTED TOP CATEGORIES: health_beauty, watches_gifts, bed_bath_table, computers
-- ============================================================

SELECT 
    COALESCE(ct.product_category_name_english, p.product_category_name) AS category,
    ROUND(SUM(oi.price + oi.freight_value), 2)                          AS category_revenue,
    COUNT(DISTINCT oi.order_id)                                          AS order_count,
    ROUND(AVG(oi.price), 2)                                             AS avg_product_price
FROM order_items oi
JOIN orders o      ON oi.order_id   = o.order_id
JOIN products p    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
                   ON p.product_category_name = ct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY COALESCE(ct.product_category_name_english, p.product_category_name)
ORDER BY category_revenue DESC
LIMIT 10;


-- ============================================================
-- QUERY 6: STATE-WISE REVENUE
-- ============================================================
-- WHAT IT DOES:
--   Shows revenue, order count, and unique customers per state.
--   Helps identify which Brazilian states are most valuable.
-- WHY JOIN customers:
--   The orders table only has customer_id; the state is in customers table.
-- EXPECTED: SP (São Paulo) by far the highest, followed by RJ, MG
-- ============================================================

SELECT 
    c.customer_state,
    ROUND(SUM(oi.price + oi.freight_value), 2)    AS state_revenue,
    COUNT(DISTINCT o.order_id)                     AS order_count,
    COUNT(DISTINCT c.customer_unique_id)           AS unique_customers
FROM orders o
JOIN order_items oi ON o.order_id  = oi.order_id
JOIN customers c    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY state_revenue DESC;


-- ============================================================
-- QUERY 7: AVERAGE ORDER VALUE BY STATE
-- ============================================================
-- WHAT IT DOES:
--   Shows the average amount spent per order in each state.
--   States with fewer but more expensive orders get a higher AOV.
-- FORMULA: SUM(revenue) / COUNT(DISTINCT orders) per state
-- ============================================================

SELECT 
    c.customer_state,
    COUNT(DISTINCT o.order_id)                                             AS order_count,
    ROUND(
        SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id),
        2
    )                                                                      AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id   = oi.order_id
JOIN customers c    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY avg_order_value DESC;


-- ============================================================
-- QUERY 8: REPEAT vs ONE-TIME CUSTOMERS
-- ============================================================
-- WHAT IT DOES:
--   Segments customers into One-Time vs Repeat buyers.
-- WHY customer_unique_id:
--   In Olist, each new order creates a NEW customer_id.
--   The SAME person ordering twice has 2 customer_ids but 1 customer_unique_id.
--   Using customer_id would make every person look like a one-time buyer!
-- STRUCTURE:
--   Inner query: counts orders per unique customer, labels as One-Time or Repeat.
--   Outer query: counts how many fall into each category.
-- SUM() OVER() in outer query: window function to get total customers for % calc.
-- EXPECTED: ~97% One-Time, ~3% Repeat
-- ============================================================

SELECT 
    customer_type,
    COUNT(*)                                                         AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)               AS percentage
FROM (
    SELECT 
        c.customer_unique_id,
        CASE 
            WHEN COUNT(DISTINCT o.order_id) = 1 THEN 'One-Time Customer'
            ELSE 'Repeat Customer'
        END AS customer_type
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
) AS customer_segments
GROUP BY customer_type;


-- ============================================================
-- QUERY 9: AVERAGE ORDERS PER CUSTOMER
-- ============================================================
-- WHAT IT DOES:
--   Total delivered orders divided by total unique customers.
--   Tells you on average how many times a customer has ordered.
-- * 1.0 ensures decimal division (MySQL integer division rounds down).
-- EXPECTED: ~1.02 to 1.03 (very close to 1 since most buy only once)
-- ============================================================

SELECT 
    ROUND(
        COUNT(DISTINCT o.order_id) * 1.0 / COUNT(DISTINCT c.customer_unique_id),
        2
    ) AS orders_per_customer
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered';


-- ============================================================
-- QUERY 10: DELIVERY DELAY ANALYSIS
-- ============================================================
-- WHAT IT DOES:
--   Compares actual delivery date vs estimated delivery date.
--   An order is DELAYED if actual delivery > estimated delivery.
-- DATEDIFF(end_date, start_date): returns difference in days.
-- CASE WHEN inside COUNT: counts only rows matching the condition.
-- NULL filters: some rows have missing dates — we exclude them.
-- EXPECTED: ~8-10% delay rate
-- ============================================================

SELECT 
    COUNT(*)                                    AS total_delivered,
    COUNT(
        CASE WHEN order_delivered_customer_date > order_estimated_delivery_date 
             THEN 1 END
    )                                           AS delayed_orders,
    COUNT(
        CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date 
             THEN 1 END
    )                                           AS on_time_orders,
    ROUND(
        COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date 
                   THEN 1 END)
        * 100.0 / COUNT(*),
        2
    )                                           AS delay_rate_pct,
    ROUND(
        AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)),
        1
    )                                           AS avg_delivery_days
FROM orders
WHERE order_status           = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;


-- ============================================================
-- QUERY 11: CTE — CUSTOMER ORDER SUMMARY BY STATE
-- ============================================================
-- WHAT IS A CTE?
--   CTE = Common Table Expression.
--   Defined with the WITH keyword — like a temporary named table.
--   Makes complex queries easier to read and understand.
--   Think of it as: FIRST calculate customer data, THEN use it.
-- STRUCTURE:
--   CTE (customer_summary): one row per unique customer with their stats.
--   Main query: uses the CTE result to summarize by state.
-- WHY USE CTE HERE?
--   Without a CTE, this would require a deeply nested subquery — hard to read.
--   CTE makes each step clear and logical.
-- ============================================================

WITH customer_summary AS (
    -- Step 1: Get each unique customer's order count and total spend
    SELECT 
        c.customer_unique_id,
        c.customer_state,
        COUNT(DISTINCT o.order_id)                    AS total_orders,
        ROUND(SUM(oi.price + oi.freight_value), 2)    AS total_spent
    FROM customers c
    JOIN orders o      ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id   = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, c.customer_state
)
-- Step 2: Use the CTE to aggregate by state
SELECT 
    customer_state,
    COUNT(customer_unique_id)                                          AS unique_customers,
    SUM(total_orders)                                                  AS total_orders,
    ROUND(AVG(total_spent), 2)                                         AS avg_customer_spend,
    SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)                 AS repeat_customers,
    ROUND(
        SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) * 100.0 
        / COUNT(customer_unique_id),
        2
    )                                                                  AS repeat_rate_pct
FROM customer_summary
GROUP BY customer_state
ORDER BY total_orders DESC;


-- ============================================================
-- QUERY 12: WINDOW FUNCTION — ROW_NUMBER() FOR CATEGORY RANKING
-- ============================================================
-- WHAT IS A WINDOW FUNCTION?
--   A function that operates on a "window" (set) of rows related to the current row.
--   Unlike GROUP BY, it does NOT collapse rows — it adds a new column.
-- ROW_NUMBER() OVER (ORDER BY ...):
--   Assigns a sequential rank: 1 to the highest, 2 to the next, and so on.
--   No ties — every row gets a unique number.
-- STRUCTURE:
--   Inner query: calculates category revenue + assigns ROW_NUMBER rank.
--   Outer query: filters to only show top 10 ranked categories.
-- WHY ROW_NUMBER() vs RANK() vs DENSE_RANK()?
--   ROW_NUMBER: 1, 2, 3, 4 — no ties, always unique
--   RANK:       1, 1, 3, 4 — ties get same rank, then skips next number
--   DENSE_RANK: 1, 1, 2, 3 — ties get same rank, no skip
-- ============================================================

SELECT *
FROM (
    SELECT 
        COALESCE(ct.product_category_name_english, p.product_category_name)  AS category,
        ROUND(SUM(oi.price + oi.freight_value), 2)                           AS category_revenue,
        COUNT(DISTINCT oi.order_id)                                           AS order_count,
        ROUND(AVG(oi.price), 2)                                              AS avg_price,
        ROW_NUMBER() OVER (
            ORDER BY SUM(oi.price + oi.freight_value) DESC
        )                                                                     AS revenue_rank
    FROM order_items oi
    JOIN orders o      ON oi.order_id   = o.order_id
    JOIN products p    ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct
                       ON p.product_category_name = ct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY COALESCE(ct.product_category_name_english, p.product_category_name)
) AS ranked_categories
WHERE revenue_rank <= 10
ORDER BY revenue_rank;

-- INTERVIEW TIP: The interviewer may ask you to also show revenue as a % of total.
-- Add this to the inner SELECT if needed:
--   ROUND(SUM(oi.price+oi.freight_value)*100 / SUM(SUM(oi.price+oi.freight_value)) OVER(), 2)
--   AS revenue_pct_of_total
