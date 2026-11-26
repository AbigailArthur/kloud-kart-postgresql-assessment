-- 1. List all distinct order statuses
SELECT
    status,
    COUNT(*) AS occurrences
FROM orders
GROUP BY status
ORDER BY occurrences DESC;


-- 2. Group order statuses after normalizing case and whitespace
SELECT
    LOWER(TRIM(status)) AS normalized_status,
    COUNT(*) AS occurrences
FROM orders
GROUP BY LOWER(TRIM(status))
ORDER BY occurrences DESC;


-- 3. Count inventory records with missing or blank notes
SELECT
    COUNT(*) AS missing_or_blank_notes
FROM inventory_log
WHERE note IS NULL
   OR TRIM(note) = '';


-- 4. Display a sample of inventory records with missing or blank notes
SELECT
    log_id,
    product_id,
    change_qty,
    reason,
    note
FROM inventory_log
WHERE note IS NULL
   OR TRIM(note) = ''
ORDER BY log_id
LIMIT 100;


-- 5. Find orders dated on or after 27 November 2026
SELECT
    order_id,
    customer_id,
    order_date
FROM orders
WHERE order_date >= DATE '2026-11-27'
ORDER BY order_date DESC;


-- 6. Count orders dated on or after 27 November 2026
SELECT
    COUNT(*) AS future_orders
FROM orders
WHERE order_date >= DATE '2026-11-27';


-- 7. Find inventory movements dated on or after 27 November 2026
SELECT
    log_id,
    product_id,
    change_qty,
    created_at
FROM inventory_log
WHERE created_at >= TIMESTAMP '2026-11-27 00:00:00'
ORDER BY created_at DESC;


-- 8. Count inventory movements dated on or after 27 November 2026
SELECT
    COUNT(*) AS future_inventory_records
FROM inventory_log
WHERE created_at >= TIMESTAMP '2026-11-27 00:00:00';


-- Assessment reference date: 27 November 2026.
