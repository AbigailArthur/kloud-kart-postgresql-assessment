-- SECTION 1: SAFE ID GENERATION
CREATE SEQUENCE IF NOT EXISTS orders_id_seq AS integer;
CREATE SEQUENCE IF NOT EXISTS order_items_id_seq AS integer;
CREATE SEQUENCE IF NOT EXISTS inventory_log_id_seq AS integer;

ALTER TABLE orders
    ALTER COLUMN order_id
    SET DEFAULT nextval('orders_id_seq');

ALTER TABLE order_items
    ALTER COLUMN order_item_id
    SET DEFAULT nextval('order_items_id_seq');

ALTER TABLE inventory_log
    ALTER COLUMN log_id
    SET DEFAULT nextval('inventory_log_id_seq');

-- Position each sequence beyond existing IDs.
SELECT setval(
    'orders_id_seq',
    GREATEST((SELECT last_value FROM orders_id_seq),
             COALESCE((SELECT MAX(order_id) FROM orders), 0)),
    true
);

SELECT setval(
    'order_items_id_seq',
    GREATEST((SELECT last_value FROM order_items_id_seq),
             COALESCE((SELECT MAX(order_item_id) FROM order_items), 0)),
    true
);

SELECT setval(
    'inventory_log_id_seq',
    GREATEST((SELECT last_value FROM inventory_log_id_seq),
             COALESCE((SELECT MAX(log_id) FROM inventory_log), 0)),
    true
);

-- =========================================================
-- SECTION 2: CONCURRENCY-SAFE ORDER PLACEMENT
-- =========================================================

CREATE OR REPLACE FUNCTION place_order(
    p_customer_id BIGINT,
    p_product_id BIGINT,
    p_quantity INTEGER
)
RETURNS TABLE (
    success BOOLEAN,
    order_id BIGINT,
    message TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_price NUMERIC(12,2);
    v_order_id INTEGER;
BEGIN
    -- Validate quantity.
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        RETURN QUERY
        SELECT FALSE, NULL::BIGINT, 'Invalid quantity'::TEXT;
        RETURN;
    END IF;

    -- Validate customer.
    IF NOT EXISTS (
        SELECT 1
        FROM customers
        WHERE customer_id = p_customer_id
    ) THEN
        RETURN QUERY
        SELECT FALSE, NULL::BIGINT, 'Customer not found'::TEXT;
        RETURN;
    END IF;

    -- Atomically check and deduct stock.
    UPDATE products
    SET stock_quantity = stock_quantity - p_quantity
    WHERE product_id = p_product_id
      AND stock_quantity >= p_quantity
    RETURNING price INTO v_price;

    -- No row updated means product is unavailable
    -- or insufficient stock remains.
    IF NOT FOUND THEN
        RETURN QUERY
        SELECT FALSE, NULL::BIGINT, 'Out of stock'::TEXT;
        RETURN;
    END IF;

    -- Create the order.
    INSERT INTO orders (
        customer_id,
        order_date,
        status,
        total_amount
    )
    VALUES (
        p_customer_id::INTEGER,
        CURRENT_TIMESTAMP,
        'pending',
        v_price * p_quantity
    )
    RETURNING orders.order_id INTO v_order_id;

    -- Create the order item.
    INSERT INTO order_items (
        order_id,
        product_id,
        quantity,
        unit_price
    )
    VALUES (
        v_order_id,
        p_product_id::INTEGER,
        p_quantity,
        v_price
    );

    -- Record the stock movement.
    INSERT INTO inventory_log (
        product_id,
        change_qty,
        reason,
        created_at,
        note
    )
    VALUES (
        p_product_id::INTEGER,
        -p_quantity,
        'sale',
        CURRENT_TIMESTAMP,
        'Order #' || v_order_id ||
        ': sale of ' || p_quantity || ' unit(s)'
    );

    RETURN QUERY
    SELECT TRUE, v_order_id::BIGINT, 'Order placed successfully'::TEXT;

END;
$$;
-- SECTION 3: REPORTING PERFORMANCE INDEX
CREATE INDEX IF NOT EXISTS idx_orders_completed_report
ON orders (order_date, customer_id)
INCLUDE (total_amount)
WHERE LOWER(BTRIM(status)) IN ('completed', 'complete');