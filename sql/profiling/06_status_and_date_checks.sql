-- 1. List all distinct order statuses
SELECT
    status,
    COUNT(*) AS occurrences
FROM orders
GROUP BY status
ORDER BY occurrences DESC;


-- 2. Group order statuses after normalizing them
SELECT
    LOWER(TRIM(status)) AS normalized_status,
    COUNT(*) AS occurrences
FROM orders
GROUP BY LOWER(TRIM(status))
ORDER BY occurrences DESC;


-- 3. Find inventory records with missing or blank notes
SELECT
    COUNT(*) AS missing_or_blank_notes
FROM inventory_log
WHERE note IS NULL
   OR TRIM(note) = '';


-- 4. Display inventory records with missing or blank notes
SELECT
    log_id,
    product_id,
    change_qty,
    reason,
    note
FROM inventory_log
WHERE note IS NULL
   OR TRIM(note) = ''
LIMIT 100;


-- 5. Find orders with future dates
SELECT
    order_id,
    customer_id,
    order_date
FROM orders
WHERE order_date > CURRENT_TIMESTAMP
ORDER BY order_date DESC;


-- 6. Count orders with future dates
SELECT
    COUNT(*) AS future_orders
FROM orders
WHERE order_date > CURRENT_TIMESTAMP;


-- 7. Find inventory records with future timestamps
SELECT
    log_id,
    product_id,
    change_qty,
    created_at
FROM inventory_log
WHERE created_at > CURRENT_TIMESTAMP
ORDER BY created_at DESC;


-- 8. Count inventory records with future timestamps
SELECT
    COUNT(*) AS future_inventory_records
FROM inventory_log
WHERE created_at > CURRENT_TIMESTAMP;
