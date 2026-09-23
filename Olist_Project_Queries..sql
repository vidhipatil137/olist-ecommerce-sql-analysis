-- ========================================================================
-- STEP 1: Create and select the database

Create Database olist_ecommerce;
Use olist_ecommerce;

-- ========================================================================
-- STEP 2: Create tables
-- customer_zip_code_prefix is VARCHAR to preserve leading zeros
Create Table customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(100),
    customer_state VARCHAR(2)
);

-- central table, linked to customers
Create Table orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- holds price/freight; composite PK since one order can have many items
Create Table order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- column names keep original CSV spelling ("lenght")
Create Table products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

Create Table sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(100),
    seller_state VARCHAR(2)
);

-- composite PK since one order can be paid in multiple ways
CREATE TABLE order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value DECIMAL(10 , 2 ),
    PRIMARY KEY (order_id , payment_sequential),
    FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
);

-- excluded from final project scope (see STEP 4 note)
Create Table order_reviews (
    review_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- Portuguese -> English category name lookup
Create Table product_category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

-- ===========================================================================
-- STEP 3: Add remaining foreign keys (products/sellers must exist first)

ALTER TABLE order_items
ADD FOREIGN KEY (product_id) REFERENCES products(product_id);
 
ALTER TABLE order_items
ADD FOREIGN KEY (seller_id) REFERENCES sellers(seller_id);

-- NOTE: products -> product_category_translation FK not added;
-- 27 category names have no translation match (see STEP 6.5)
-- ============================================================================
-- STEP 4: Data imported via MySQL Workbench Table Data Import Wizard
-- from the matching CSV file for each table.
-- order_reviews left empty and excluded from scope (import kept failing)

-- ============================================================================
-- STEP 5: Verify row counts for all tables

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'product_category_translation', COUNT(*) FROM product_category_translation;

-- ===========================================================================
-- STEP 6: Data validation

SET SQL_SAFE_UPDATES = 0;

-- 6.1 check for duplicate order_id (expect 0 rows)
SELECT order_id, COUNT(*) AS cnt
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 6.2 distribution of order_status
SELECT order_status, COUNT(*) AS total
FROM orders
GROUP BY order_status
ORDER BY total DESC;

-- 6.3 date range of the dataset
SELECT
    MIN(order_purchase_timestamp) AS earliest_order,
    MAX(order_purchase_timestamp) AS latest_order
FROM orders;

-- 6.4 fix bad placeholder dates ('0000-00-00') -> real NULL
UPDATE orders
SET order_delivered_customer_date = NULL
WHERE order_delivered_customer_date = '0000-00-00 00:00:00';

UPDATE orders
SET order_approved_at = NULL
WHERE order_approved_at = '0000-00-00 00:00:00';
 
UPDATE orders
SET order_delivered_carrier_date = NULL
WHERE order_delivered_carrier_date = '0000-00-00 00:00:00';

-- verify the fix
SELECT
    COUNT(*) AS total,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS null_delivered,
    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS null_approved,
    SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS null_carrier_date
FROM orders;

-- 6.5 product categories with no translation match (known data gap)
SELECT DISTINCT p.product_category_name
FROM products p
LEFT JOIN product_category_translation t
    ON p.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL
  AND p.product_category_name IS NOT NULL;
  
  -- products with a fully missing category (expect 0)
SELECT COUNT(*) AS products_without_category
FROM products
WHERE product_category_name IS NULL;

-- 6.6 fix blank text-length values -> real NULL
UPDATE products
SET product_name_lenght = NULL
WHERE product_name_lenght = '';
 
UPDATE products
SET product_description_lenght = NULL
WHERE product_description_lenght = '';

-- verify the fix
SELECT COUNT(*) AS blank_name_length FROM products WHERE product_name_lenght = '';
SELECT COUNT(*) AS blank_desc_length FROM products WHERE product_description_lenght = '';

-- 6.7 quick quality check on remaining tables
-- customers: blank city/state
SELECT
    SUM(CASE WHEN customer_city = '' OR customer_city IS NULL THEN 1 ELSE 0 END) AS blank_city,
    SUM(CASE WHEN customer_state = '' OR customer_state IS NULL THEN 1 ELSE 0 END) AS blank_state
FROM customers;

-- order_items: price / freight / shipping date
SELECT
    COUNT(*) AS total,
    SUM(CASE WHEN price = 0 OR price IS NULL THEN 1 ELSE 0 END) AS zero_price,
    SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) AS null_freight,
    SUM(CASE WHEN shipping_limit_date = '0000-00-00 00:00:00' THEN 1 ELSE 0 END) AS bad_shipping_date
FROM order_items;

-- order_payments: zero-value payments
SELECT
    COUNT(*) AS total,
    SUM(CASE WHEN payment_value = 0 OR payment_value IS NULL THEN 1 ELSE 0 END) AS zero_payment,
    SUM(CASE WHEN payment_type = '' OR payment_type IS NULL THEN 1 ELSE 0 END) AS blank_payment_type,
    SUM(CASE WHEN payment_installments IS NULL THEN 1 ELSE 0 END) AS null_installments
FROM order_payments;

-- products: remaining columns
SELECT
    COUNT(*) AS total,
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN product_weight_g IS NULL OR product_weight_g = 0 THEN 1 ELSE 0 END) AS zero_weight,
    SUM(CASE WHEN product_photos_qty IS NULL THEN 1 ELSE 0 END) AS null_photos_qty
FROM products;

-- sellers: blank city/state
SELECT
    SUM(CASE WHEN seller_city = '' OR seller_city IS NULL THEN 1 ELSE 0 END) AS blank_city,
    SUM(CASE WHEN seller_state = '' OR seller_state IS NULL THEN 1 ELSE 0 END) AS blank_state
FROM sellers;
-- ============================================================================
-- STEP 7: SQL Analysis
-- Q1: total orders by status, with percentage

SELECT 
    order_status, 
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) AS percentage
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- Q2: top 10 states by number of customers
SELECT 
    customer_state, 
    COUNT(*) AS total_customers
FROM customers
GROUP BY customer_state
ORDER BY total_customers DESC
LIMIT 10;

-- Q3: top 10 product categories by number of items sold
SELECT 
    t.product_category_name_english AS category,
    COUNT(*) AS items_sold
FROM order_items oi
INNER JOIN products p ON oi.product_id = p.product_id
INNER JOIN product_category_translation t ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
ORDER BY items_sold DESC
LIMIT 10;

-- Q4: monthly revenue trend
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    SUM(oi.price) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
INNER JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY order_month
ORDER BY order_month;

-- Q5: top 10 products by total revenue
SELECT 
    product_id,
    SUM(price) AS total_revenue,
    COUNT(*) AS times_ordered
FROM order_items
GROUP BY product_id
ORDER BY total_revenue DESC
LIMIT 10;

-- Q6: payment method distribution
SELECT 
    payment_type,
    COUNT(*) AS total_transactions,
    SUM(payment_value) AS total_amount,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM order_payments), 2) AS percentage
FROM order_payments
GROUP BY payment_type
ORDER BY total_transactions DESC;

-- Q7: top 3 best-selling products within each category
WITH ranked_products AS (
    SELECT 
        t.product_category_name_english AS category,
        oi.product_id,
        COUNT(*) AS times_sold,
        RANK() OVER (PARTITION BY t.product_category_name_english ORDER BY COUNT(*) DESC) AS rnk
    FROM order_items oi
    INNER JOIN products p ON oi.product_id = p.product_id
    INNER JOIN product_category_translation t ON p.product_category_name = t.product_category_name
    GROUP BY t.product_category_name_english, oi.product_id
)
SELECT * FROM ranked_products
WHERE rnk <= 3
ORDER BY category, rnk;

-- Q8: month-over-month revenue growth %
WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        SUM(oi.price) AS total_revenue
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY order_month
)
SELECT 
    order_month,
    total_revenue,
    LAG(total_revenue) OVER (ORDER BY order_month) AS previous_month_revenue,
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY order_month)) 
        / LAG(total_revenue) OVER (ORDER BY order_month) * 100, 2
    ) AS growth_percentage
FROM monthly_revenue
ORDER BY order_month;

-- Q9: customers who spent more than the average customer
SELECT 
    c.customer_unique_id,
    SUM(oi.price) AS total_spent
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_unique_id
HAVING SUM(oi.price) > (
    SELECT AVG(customer_total) FROM (
        SELECT SUM(oi2.price) AS customer_total
        FROM customers c2
        INNER JOIN orders o2 ON c2.customer_id = o2.customer_id
        INNER JOIN order_items oi2 ON o2.order_id = oi2.order_id
        GROUP BY c2.customer_unique_id
    ) AS customer_totals
)
ORDER BY total_spent DESC
LIMIT 10;

-- Q10: how many customers ordered more than once
SELECT 
    COUNT(*) AS repeat_customers
FROM (
    SELECT customer_unique_id
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY customer_unique_id
    HAVING COUNT(DISTINCT o.order_id) > 1
) AS repeat_cust;

-- Q11: average delivery time and % of late deliveries
SELECT 
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) AS avg_delivery_days,
    ROUND(
        SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) 
        * 100.0 / COUNT(*), 2
    ) AS late_delivery_percentage
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

-- Q12: segment customers by total spending
WITH customer_spending AS (
    SELECT 
        c.customer_unique_id,
        SUM(oi.price) AS total_spent
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)
SELECT 
    CASE 
        WHEN total_spent >= 500 THEN 'High Spender'
        WHEN total_spent >= 150 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS customer_segment,
    COUNT(*) AS number_of_customers,
    ROUND(AVG(total_spent), 2) AS avg_spent
FROM customer_spending
GROUP BY customer_segment
ORDER BY avg_spent DESC;





