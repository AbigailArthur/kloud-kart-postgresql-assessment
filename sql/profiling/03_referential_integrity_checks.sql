--- 1. Orders referencing customers that do not exist
SELECT
    o.order_id,
    o.customer_id
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- 2. Order items referencing orders that do not exist
SELECT
    oi.order_item_id,
    oi.order_id
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 3. Order items referencing products that do not exist
SELECT
    oi.order_item_id,
    oi.product_id
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- 4. Products referencing categories that do not exist
SELECT
    p.product_id,
    p.product_name,
    p.category_id
FROM products p
LEFT JOIN categories c
    ON p.category_id = c.category_id
WHERE p.category_id IS NOT NULL
  AND c.category_id IS NULL;


-- 5. Inventory records referencing products that do not exist
SELECT
    il.log_id,
    il.product_id,
    il.change_qty,
    il.reason
FROM inventory_log il
LEFT JOIN products p
    ON il.product_id = p.product_id
WHERE p.product_id IS NULL;


-- 6. Categories referencing parent categories that do not exist
SELECT
    child.category_id,
    child.category_name,
    child.parent_id
FROM categories child
LEFT JOIN categories parent
    ON child.parent_id = parent.category_id
WHERE child.parent_id IS NOT NULL
  AND parent.category_id IS NULL;


-- 7. Summary: Count orphan records in each relationship
SELECT 'Orders without customers' AS issue, COUNT(*) AS affected_records
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT 'Order items without orders', COUNT(*)
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT 'Order items without products', COUNT(*)
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT 'Products with invalid categories', COUNT(*)
FROM products p
LEFT JOIN categories c ON p.category_id = c.category_id
WHERE p.category_id IS NOT NULL
  AND c.category_id IS NULL

UNION ALL

SELECT 'Inventory records without products', COUNT(*)
FROM inventory_log il
LEFT JOIN products p ON il.product_id = p.product_id
WHERE p.product_id IS NULL;
