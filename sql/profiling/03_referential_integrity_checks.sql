-- FILE 03: REFERENTIAL INTEGRITY CHECKS
-- Identify records that reference missing parent records.
-- A temporary view calculates orphan records once and is reused
-- for the detailed output and summary.

\echo 'Building shared orphan-record results'

CREATE OR REPLACE TEMP VIEW profiling_orphan_records AS

-- 1. Orders referencing customers that do not exist
SELECT
    'Orders without customers' AS issue,
    o.order_id::TEXT AS record_id,
    o.customer_id::TEXT AS related_id,
    NULL::TEXT AS extra_detail
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

-- 2. Order items referencing orders that do not exist
SELECT
    'Order items without orders',
    oi.order_item_id::TEXT,
    oi.order_id::TEXT,
    NULL::TEXT
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

-- 3. Order items referencing products that do not exist
SELECT
    'Order items without products',
    oi.order_item_id::TEXT,
    oi.product_id::TEXT,
    NULL::TEXT
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

-- 4. Products referencing categories that do not exist
SELECT
    'Products with invalid categories',
    p.product_id::TEXT,
    p.category_id::TEXT,
    p.product_name
FROM products p
LEFT JOIN categories c
    ON p.category_id = c.category_id
WHERE p.category_id IS NOT NULL
  AND c.category_id IS NULL

UNION ALL

-- 5. Inventory records referencing products that do not exist
SELECT
    'Inventory records without products',
    il.log_id::TEXT,
    il.product_id::TEXT,
    CONCAT(
        'change_qty=', COALESCE(il.change_qty::TEXT, 'NULL'),
        '; reason=', COALESCE(il.reason, 'NULL')
    )
FROM inventory_log il
LEFT JOIN products p
    ON il.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

-- 6. Categories referencing parent categories that do not exist
SELECT
    'Categories without valid parent categories',
    child.category_id::TEXT,
    child.parent_id::TEXT,
    child.category_name
FROM categories child
LEFT JOIN categories parent
    ON child.parent_id = parent.category_id
WHERE child.parent_id IS NOT NULL
  AND parent.category_id IS NULL;


\echo '1-6. Detailed orphan records'

SELECT
    issue,
    record_id,
    related_id,
    extra_detail
FROM profiling_orphan_records
ORDER BY issue, record_id;


\echo '7. Summary of orphan records'

WITH issue_list(issue) AS (
    VALUES
        ('Orders without customers'),
        ('Order items without orders'),
        ('Order items without products'),
        ('Products with invalid categories'),
        ('Inventory records without products'),
        ('Categories without valid parent categories')
),
orphan_counts AS (
    SELECT issue, COUNT(*) AS affected_records
    FROM profiling_orphan_records
    GROUP BY issue
)
SELECT
    i.issue,
    COALESCE(o.affected_records, 0) AS affected_records
FROM issue_list i
LEFT JOIN orphan_counts o
    ON i.issue = o.issue
ORDER BY i.issue;
