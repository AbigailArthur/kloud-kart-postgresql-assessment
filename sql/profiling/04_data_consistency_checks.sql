-- 1. Find products with negative stock
SELECT
    product_id,
    product_name,
    stock_quantity
FROM products
WHERE stock_quantity < 0
ORDER BY stock_quantity;


-- 2. Find products with zero or negative prices
SELECT
    product_id,
    product_name,
    price
FROM products
WHERE price <= 0;


-- 3. Find order items with zero or negative quantities
SELECT
    order_item_id,
    order_id,
    product_id,
    quantity
FROM order_items
WHERE quantity <= 0;


-- 4. Find order items with zero or negative unit prices
SELECT
    order_item_id,
    order_id,
    product_id,
    unit_price
FROM order_items
WHERE unit_price <= 0;


-- 5. Compare stored order totals with calculated totals
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
HAVING ABS(
    o.total_amount -
    COALESCE(SUM(oi.quantity * oi.unit_price), 0)
) > 0.01
ORDER BY ABS(
    o.total_amount -
    COALESCE(SUM(oi.quantity * oi.unit_price), 0)
) DESC;


-- 6. Count orders with inconsistent totals
SELECT
    COUNT(*) AS inconsistent_order_count
FROM (
    SELECT
        o.order_id
    FROM orders o
    LEFT JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.total_amount
    HAVING ABS(
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
WHERE change_qty = 0;
