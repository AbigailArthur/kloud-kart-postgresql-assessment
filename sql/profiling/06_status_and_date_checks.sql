
-- ============================================================
-- 06. STATUS, INVENTORY NOTES AND DATE CHECKS
-- Kloud-Kart PostgreSQL Assessment
-- Assessment reference date: 27 November 2026
-- ============================================================


-- 1. List all distinct raw order statuses
SELECT
    status,
    COUNT(*) AS occurrences
FROM orders
GROUP BY status
ORDER BY occurrences DESC, status;


-- 2. Group statuses after normalizing case and whitespace
-- Note: Semantic synonyms such as complete/completed
-- are not automatically merged here.
SELECT
    LOWER(TRIM(status)) AS normalized_status,
    COUNT(*) AS occurrences
FROM orders
GROUP BY LOWER(TRIM(status))
ORDER BY occurrences DESC, normalized_status;


-- 3. Summarize spelling and formatting variations
SELECT
    COUNT(DISTINCT status) AS distinct_raw_statuses,
    COUNT(DISTINCT LOWER(TRIM(status))) AS normalized_status_groups
FROM orders;


-- 4. Count orders with missing or blank statuses
SELECT
    COUNT(*) AS orders_with_missing_or_blank_status
FROM orders
WHERE status IS NULL
   OR TRIM(status) = '';


-- 5. Count inventory records with missing or blank notes
SELECT
    COUNT(*) AS missing_or_blank_notes
FROM inventory_log
WHERE note IS NULL
   OR TRIM(note) = '';


-- 6. Display a deterministic sample of inventory records
--    with missing notes.
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


-- 7. Find orders dated on or after the assessment reference date
SELECT
    order_id,
    customer_id,
    order_date
FROM orders
WHERE order_date >= DATE '2026-11-27'
ORDER BY order_date DESC, order_id;


-- 8. Count orders dated on or after the assessment reference date
SELECT
    COUNT(*) AS orders_on_or_after_reference_date
FROM orders
WHERE order_date >= DATE '2026-11-27';


-- 9. Find inventory movements dated on or after the reference date
SELECT
    log_id,
    product_id,
    change_qty,
    created_at
FROM inventory_log
WHERE created_at >= TIMESTAMP '2026-11-27 00:00:00'
ORDER BY created_at DESC, log_id;


-- 10. Count inventory movements dated on or after the reference date
SELECT
    COUNT(*) AS inventory_records_on_or_after_reference_date
FROM inventory_log
WHERE created_at >= TIMESTAMP '2026-11-27 00:00:00';


-- 11. Find orders placed before the customer's registration date
-- These may indicate incorrect timestamps or customer-order associations.
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    c.registered_at,
    c.registered_at::DATE - o.order_date::DATE
        AS days_before_customer_registration
FROM orders o
INNER JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_date IS NOT NULL
  AND c.registered_at IS NOT NULL
  AND o.order_date < c.registered_at
ORDER BY o.order_date, o.order_id;


-- 12. Count orders placed before the customer's registration date
SELECT
    COUNT(*) AS orders_before_customer_registration
FROM orders o
INNER JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_date IS NOT NULL
  AND c.registered_at IS NOT NULL
  AND o.order_date < c.registered_at;
