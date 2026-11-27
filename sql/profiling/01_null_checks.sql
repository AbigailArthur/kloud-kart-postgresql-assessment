-- FILE 01: NULL / MISSING VALUE CHECKS
-- Checks SQL NULLs and blank text values.

-- 1. Categories
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE category_name IS NULL) AS missing_category_names,
    COUNT(*) FILTER (WHERE category_name IS NOT NULL AND TRIM(category_name) = '') AS blank_category_names,
    COUNT(*) FILTER (WHERE parent_id IS NULL) AS root_categories
FROM categories;

-- 2. Products
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE product_name IS NULL) AS missing_product_names,
    COUNT(*) FILTER (WHERE product_name IS NOT NULL AND TRIM(product_name) = '') AS blank_product_names,
    COUNT(*) FILTER (WHERE category_id IS NULL) AS missing_category_ids,
    COUNT(*) FILTER (WHERE price IS NULL) AS missing_prices,
    COUNT(*) FILTER (WHERE stock_quantity IS NULL) AS missing_stock_values
FROM products;

-- 3. Customers
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE full_name IS NULL) AS missing_names,
    COUNT(*) FILTER (WHERE full_name IS NOT NULL AND TRIM(full_name) = '') AS blank_names,
    COUNT(*) FILTER (WHERE email IS NULL) AS missing_emails,
    COUNT(*) FILTER (WHERE email IS NOT NULL AND TRIM(email) = '') AS blank_emails,
    COUNT(*) FILTER (WHERE phone IS NULL) AS missing_phone_numbers,
    COUNT(*) FILTER (WHERE phone IS NOT NULL AND TRIM(phone) = '') AS blank_phone_numbers,
    COUNT(*) FILTER (WHERE city IS NULL) AS missing_cities,
    COUNT(*) FILTER (WHERE city IS NOT NULL AND TRIM(city) = '') AS blank_cities
FROM customers;

-- 4. Orders
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_ids,
    COUNT(*) FILTER (WHERE order_date IS NULL) AS missing_order_dates,
    COUNT(*) FILTER (WHERE status IS NULL) AS missing_statuses,
    COUNT(*) FILTER (WHERE status IS NOT NULL AND TRIM(status) = '') AS blank_statuses,
    COUNT(*) FILTER (WHERE total_amount IS NULL) AS missing_total_amounts
FROM orders;

-- 5. Order items
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_ids,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS missing_product_ids,
    COUNT(*) FILTER (WHERE quantity IS NULL) AS missing_quantities,
    COUNT(*) FILTER (WHERE unit_price IS NULL) AS missing_unit_prices
FROM order_items;

-- 6. Inventory log
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS missing_product_ids,
    COUNT(*) FILTER (WHERE change_qty IS NULL) AS missing_change_quantities,
    COUNT(*) FILTER (WHERE reason IS NULL) AS missing_reasons,
    COUNT(*) FILTER (WHERE reason IS NOT NULL AND TRIM(reason) = '') AS blank_reasons,
    COUNT(*) FILTER (WHERE note IS NULL) AS missing_notes,
    COUNT(*) FILTER (WHERE note IS NOT NULL AND TRIM(note) = '') AS blank_notes
FROM inventory_log;
