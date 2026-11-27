-- FILE 01: NULL / MISSING VALUE CHECKS
-- Checks SQL NULLs and blank text values.

-- 1. Categories
\echo 'Categories: missing and root values'
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE category_name IS NULL) AS missing_category_names,
    COUNT(*) FILTER (WHERE category_name IS NOT NULL AND TRIM(category_name) = '') AS blank_category_names,
    COUNT(*) FILTER (WHERE parent_id IS NULL) AS root_categories
FROM categories;

-- 2. Products
\echo 'Products: missing values'
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE product_name IS NULL) AS missing_product_names,
    COUNT(*) FILTER (WHERE product_name IS NOT NULL AND TRIM(product_name) = '') AS blank_product_names,
    COUNT(*) FILTER (WHERE category_id IS NULL) AS missing_category_ids,
    COUNT(*) FILTER (WHERE price IS NULL) AS missing_prices,
    COUNT(*) FILTER (WHERE stock_quantity IS NULL) AS missing_stock_values
FROM products;

-- 3. Customers
\echo 'Customers: missing values'
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
\echo 'Orders: missing values'
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_ids,
    COUNT(*) FILTER (WHERE order_date IS NULL) AS missing_order_dates,
    COUNT(*) FILTER (WHERE status IS NULL) AS missing_statuses,
    COUNT(*) FILTER (WHERE status IS NOT NULL AND TRIM(status) = '') AS blank_statuses,
    COUNT(*) FILTER (WHERE total_amount IS NULL) AS missing_total_amounts
FROM orders;

-- 5. Order items
\echo 'Order items: missing values'
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_ids,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS missing_product_ids,
    COUNT(*) FILTER (WHERE quantity IS NULL) AS missing_quantities,
    COUNT(*) FILTER (WHERE unit_price IS NULL) AS missing_unit_prices
FROM order_items;

-- 6. Inventory log
\echo 'Inventory log: missing values'
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS missing_product_ids,
    COUNT(*) FILTER (WHERE change_qty IS NULL) AS missing_change_quantities,
    COUNT(*) FILTER (WHERE reason IS NULL) AS missing_reasons,
    COUNT(*) FILTER (WHERE reason IS NOT NULL AND TRIM(reason) = '') AS blank_reasons,
    COUNT(*) FILTER (WHERE note IS NULL) AS missing_notes,
    COUNT(*) FILTER (WHERE note IS NOT NULL AND TRIM(note) = '') AS blank_notes
FROM inventory_log;

-- 7. NUMERIC RANGE AND OUTLIER CHECKS
--
-- Uses the 1.5 x IQR rule to flag unusually low or high values.
-- These are statistical outliers for investigation, not automatic errors.
-- Existing NULL and non-positive checks remain in the other profiling files.

\echo '7. Numeric range and outlier checks'

WITH metric_values AS (
    SELECT
        'products.price' AS metric_name,
        product_id::TEXT AS record_id,
        price AS metric_value
    FROM products
    WHERE price IS NOT NULL

    UNION ALL

    SELECT
        'products.stock_quantity',
        product_id::TEXT,
        stock_quantity::NUMERIC
    FROM products
    WHERE stock_quantity IS NOT NULL

    UNION ALL

    SELECT
        'orders.total_amount',
        order_id::TEXT,
        total_amount
    FROM orders
    WHERE total_amount IS NOT NULL

    UNION ALL

    SELECT
        'order_items.quantity',
        order_item_id::TEXT,
        quantity::NUMERIC
    FROM order_items
    WHERE quantity IS NOT NULL

    UNION ALL

    SELECT
        'order_items.unit_price',
        order_item_id::TEXT,
        unit_price
    FROM order_items
    WHERE unit_price IS NOT NULL

    UNION ALL

    SELECT
        'inventory_log.absolute_change_qty',
        log_id::TEXT,
        ABS(change_qty::NUMERIC)
    FROM inventory_log
    WHERE change_qty IS NOT NULL
),
quartiles AS (
    SELECT
        metric_name,
        COUNT(*) AS total_values,
        PERCENTILE_CONT(0.25) WITHIN GROUP (
            ORDER BY metric_value
        ) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (
            ORDER BY metric_value
        ) AS q3,
        MAX(metric_value) AS maximum_value
    FROM metric_values
    GROUP BY metric_name
),
boundaries AS (
    SELECT
        metric_name,
        total_values,
        q1,
        q3,
        q1 - 1.5 * (q3 - q1) AS lower_fence,
        q3 + 1.5 * (q3 - q1) AS upper_fence,
        maximum_value
    FROM quartiles
)
SELECT
    b.metric_name,
    b.total_values,
    ROUND(b.q1::NUMERIC, 2) AS first_quartile,
    ROUND(b.q3::NUMERIC, 2) AS third_quartile,
    ROUND(b.lower_fence::NUMERIC, 2) AS lower_outlier_boundary,
    ROUND(b.upper_fence::NUMERIC, 2) AS upper_outlier_boundary,
    COUNT(m.record_id) FILTER (
        WHERE m.metric_value < b.lower_fence
           OR m.metric_value > b.upper_fence
    ) AS outlier_count,
    ROUND(b.maximum_value::NUMERIC, 2) AS maximum_observed_value
FROM boundaries b
JOIN metric_values m
    ON m.metric_name = b.metric_name
GROUP BY
    b.metric_name,
    b.total_values,
    b.q1,
    b.q3,
    b.lower_fence,
    b.upper_fence,
    b.maximum_value
ORDER BY b.metric_name;