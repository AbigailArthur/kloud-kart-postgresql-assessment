
-- ============================================================
-- 04. DATA CONSISTENCY CHECKS
-- Kloud-Kart PostgreSQL Assessment
-- ============================================================


-- 1. Find products with negative stock
SELECT
    product_id,
    product_name,
    stock_quantity
FROM products
WHERE stock_quantity < 0
ORDER BY stock_quantity, product_id;


-- 2. Find products with zero or negative prices
SELECT
    product_id,
    product_name,
    price
FROM products
WHERE price <= 0
ORDER BY product_id;


-- 3. Find order items with zero or negative quantities
SELECT
    order_item_id,
    order_id,
    product_id,
    quantity
FROM order_items
WHERE quantity <= 0
ORDER BY order_item_id;


-- 4. Find order items with zero or negative unit prices
SELECT
    order_item_id,
    order_id,
    product_id,
    unit_price
FROM order_items
WHERE unit_price <= 0
ORDER BY order_item_id;


-- 5. Compare stored totals with calculated totals
--    Only include orders where every order item has a unit price.
SELECT
    o.order_id,
    o.total_amount AS stored_total,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS calculated_total,
    o.total_amount -
        COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS difference
FROM orders o
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.order_id, o.total_amount
HAVING COUNT(oi.order_item_id)
           FILTER (WHERE oi.unit_price IS NULL) = 0
   AND ABS(
       o.total_amount -
       COALESCE(SUM(oi.quantity * oi.unit_price), 0)
   ) > 0.01
ORDER BY ABS(
    o.total_amount -
    COALESCE(SUM(oi.quantity * oi.unit_price), 0)
) DESC, o.order_id;


-- 6. Count fully priced orders with inconsistent totals
SELECT
    COUNT(*) AS inconsistent_fully_priced_orders
FROM (
    SELECT
        o.order_id
    FROM orders o
    LEFT JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.total_amount
    HAVING COUNT(oi.order_item_id)
               FILTER (WHERE oi.unit_price IS NULL) = 0
       AND ABS(
           o.total_amount -
           COALESCE(SUM(oi.quantity * oi.unit_price), 0)
       ) > 0.01
) AS inconsistent_orders;


-- 7. Find inventory records with zero quantity changes
SELECT
    log_id,
    product_id,
    change_qty,
    reason
FROM inventory_log
WHERE change_qty = 0
ORDER BY log_id;


-- 8. Count products with negative stock
SELECT
    COUNT(*) AS products_with_negative_stock
FROM products
WHERE stock_quantity < 0;


-- 9. Count order items with non-positive quantities
SELECT
    COUNT(*) AS order_items_with_nonpositive_quantity
FROM order_items
WHERE quantity <= 0;


-- 10. Count order items with non-positive unit prices
SELECT
    COUNT(*) AS order_items_with_nonpositive_unit_price
FROM order_items
WHERE unit_price <= 0;


-- 11. Find sale inventory movements with positive quantities
--     These may indicate incorrectly classified movements.
SELECT
    log_id,
    product_id,
    change_qty,
    reason
FROM inventory_log
WHERE LOWER(BTRIM(reason)) = 'sale'
  AND change_qty > 0
ORDER BY log_id;


-- 12. Find non-sale inventory movements with negative quantities
--     These may indicate incorrectly classified movements.
SELECT
    log_id,
    product_id,
    change_qty,
    reason
FROM inventory_log
WHERE LOWER(BTRIM(reason)) <> 'sale'
  AND change_qty < 0
ORDER BY log_id;
