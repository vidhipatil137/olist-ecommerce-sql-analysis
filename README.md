# Olist E-Commerce Sales & Customer Analytics using SQL

## Overview
This is a SQL data analysis project built on the real-world **Brazilian E-Commerce Public Dataset by Olist** (Kaggle). Olist is one of the largest department-store marketplaces in Brazil, and this dataset contains ~100k real orders placed between 2016 and 2018 across multiple linked tables (customers, orders, order items, products, sellers, and payments).

The project covers the full analyst workflow: database design, data import, data cleaning/validation, and SQL analysis (beginner to advanced), using MySQL.

## Problem Statement
Olist has raw transactional data spread across multiple tables covering sales, customers, products, payments, and delivery, but this data cannot directly answer business questions in its raw form. This project uses SQL to structure, clean, and analyze this data to uncover insights on sales performance, customer behavior, delivery efficiency, and product/category trends.

## Objectives
- Structure raw multi-table e-commerce data into a relational MySQL database
- Validate and clean the data (nulls, duplicates, incorrect data types)
- Analyze sales, customer, and product trends using SQL
- Study delivery performance and its relationship to sales patterns
- Use window functions and CTEs to extract advanced business insights
- Document findings in a clear, professional format

## Dataset
- **Source:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle)
- **Period covered:** September 2016 to October 2018
- **Scope:** 6 of the 9 original CSV files were used as the project's core tables (see *Data Limitations* below for the two that were excluded, and why)

| Table | Description |
|---|---|
| customers | Customer ID and location (city/state) |
| orders | Order status and purchase/delivery timestamps |
| order_items | Line items per order, with price and freight value |
| order_payments | Payment type, installments, and value per order |
| products | Product category and physical attributes |
| sellers | Seller ID and location |
| product_category_translation | Portuguese-to-English category name mapping |

## Database Schema
- **Database:** `olist_ecommerce` (MySQL 8.0)
- `orders` is the central table, connected to `customers` via `customer_id`
- `order_items` connects `orders` to `products` and `sellers`
- `order_payments` connects to `orders` via `order_id`
- `products` connects to `product_category_translation` via `product_category_name` (join only — no FK, see limitations)

Full schema (`CREATE TABLE` statements with keys and data types) is in [`Olist_Project_Queries.sql`](./Olist_Project_Queries.sql).

## Tools Used
- MySQL 8.0
- MySQL Workbench

## SQL Concepts Used
`SELECT`, `WHERE`, `GROUP BY`, `HAVING`, `ORDER BY`, Aggregate functions (`COUNT`, `SUM`, `AVG`), `INNER JOIN`, `LEFT JOIN`, Subqueries, `CASE`, Date functions (`DATE_FORMAT`, `DATEDIFF`), `CTE (WITH)`, Window functions (`RANK`, `LAG`)

## Data Cleaning & Validation
Before analysis, the raw data was checked and cleaned:
- Found and fixed **2,965 orders** where the delivery date had been stored as a placeholder `0000-00-00` instead of a proper NULL
- Found and fixed **610 rows** in `products` with blank text-length fields, converted to NULL
- Found **27 product categories** with no matching English translation (a gap in the original dataset) — a foreign key was not enforced here, so a `LEFT JOIN` is used when this relationship is needed
- Found **6 products** with a weight of 0 — a negligible data issue, left as-is
- Verified no duplicate `order_id` values, and no missing state/city values in `customers` or `sellers`

## Data Limitations
- **`olist_geolocation_dataset.csv`** was excluded from scope — it contains ~1 million rows of largely duplicate zip-code data not needed for any business question in this project.
- **`order_reviews`** table structure was created but left unpopulated due to a recurring technical issue during import, and was excluded from the project's final scope. As a result, review-score-related questions (e.g. "does late delivery lower review scores?") are not covered here.

## Business Questions & Key Insights

**1. What are the order statuses, and how are they distributed?**
97.02% of all 99,441 orders were successfully delivered; only ~1.24% were canceled or unavailable — a healthy fulfillment rate.

**2. Which states have the most customers?**
São Paulo (SP) alone accounts for ~42% of all customers (41,746 of 99,441). The top 3 states (SP, RJ, MG) together cover over two-thirds of the customer base.

**3. Which product categories sell the most?**
Health & Beauty leads (9,670 items sold), followed by Furniture & Decor and Computers & Accessories.

**4. What is the monthly sales trend?**
Revenue grew steadily through 2017, peaking sharply in November 2017 (+52% month-over-month, likely Black Friday), then plateaued through 2018 at a mature, stable level.

**5. Which products generate the most revenue?**
A mix of two patterns: a few high-price, low-volume "premium" products, and several low-price, high-volume "everyday" products drive the top revenue list.

**6. How do customers pay?**
Credit card dominates at 73.92% of all transactions and the majority of revenue; boleto (a local Brazilian payment method) is a distant second at 19.04%.

**7. What are the top 3 best-selling products within each category?**
Some categories are driven by a single "hero product" (e.g. one Furniture & Decor item sold 527 times), while others (e.g. Health & Beauty) have demand spread more evenly across several products.

**8. What is the month-over-month growth rate?**
Growth was volatile in 2016–2017 (small base), spiked in November 2017, and stabilized into a mature ±15% monthly range through 2018.

**9. Which customers spend above average?**
A small set of customers spend well above the average order value, up to ₹13,440 — clear high-value customer candidates for loyalty programs.

**10. How many customers are repeat buyers?**
Only 2,997 customers (about 3% of the customer base) placed more than one order — a significant customer retention gap.

**11. What is the average delivery time, and how many deliveries are late?**
Average delivery time is 12.5 days; 8.11% of delivered orders arrive later than the estimated delivery date.

**12. How do customers segment by spending?**
High Spenders (≥₹500) are only ~4% of customers but spend 13x more on average (₹930.58) than Low Spenders (₹70.06, ~74% of customers).

## Recommendations
- Focus marketing and logistics investment on the SP, RJ, and MG regions, which drive the majority of the customer base
- Prioritize Health & Beauty, Furniture & Decor, and Computers & Accessories for inventory and marketing focus
- Plan for demand spikes around November (Black Friday season) in inventory and staffing
- Investigate and address the 8.11% late-delivery rate, as it is a likely driver of customer dissatisfaction
- Build a retention strategy (loyalty programs, targeted offers) to address the low 3% repeat-purchase rate
- Design tiered loyalty rewards to protect and grow the small but highly valuable High Spender segment

## Conclusion
This project demonstrates the full workflow of a real-world SQL data analysis project — from raw multi-table CSV data to a clean, validated relational database, to business-driven insights using SQL ranging from basic aggregation to window functions and CTEs. The analysis surfaces both strong points (high delivery success rate, clear top-performing categories) and clear areas for business improvement (customer retention, delivery timeliness).
