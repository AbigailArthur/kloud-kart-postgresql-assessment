-- KLOUD KART: PostgreSQL database solution
--
-- This script provides:
--   1. Safe ID generation for existing and new records.
--   2. Concurrency-safe order placement.
--   3. Controlled inventory adjustments.
--   4. Recursive low-stock reporting with category hierarchy checks.
--
-- Run after sql/schema.sql and sql/load.sql.
-- Execute against a fresh or disposable assessment database first.


-- ============================================================
-- 1. ID GENERATION
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS orders_id_seq AS INTEGER;
CREATE SEQUENCE IF NOT EXISTS order_items_id_seq AS INTEGER;
CREATE SEQUENCE IF NOT EXISTS inventory_log_id_seq AS INTEGER;

ALTER TABLE orders
    ALTER COLUMN order_id SET DEFAULT nextval('orders_id_seq');

ALTER TABLE order_items
    ALTER COLUMN order_item_id SET DEFAULT nextval('order_items_id_seq');

ALTER TABLE inventory_log
    ALTER COLUMN log_id SET DEFAULT nextval('inventory_log_id_seq');


-- Initialize sequences without generating duplicate IDs.
-- Empty tables retain the first available ID of 1.
-- Existing sequence values are never moved backwards.

SELECT setval(
    'orders_id_seq',
    GREATEST(
        (SELECT last_value FROM orders_id_seq),
        COALESCE((SELECT MAX(order_id) FROM orders), 1)
    ),
    (SELECT is_called FROM orders_id_seq)
        OR EXISTS (SELECT 1 FROM orders)
);

SELECT setval(
    'order_items_id_seq',
    GREATEST(
        (SELECT last_value FROM order_items_id_seq),
        COALESCE((SELECT MAX(order_item_id) FROM order_items), 1)
    ),
    (SELECT is_called FROM order_items_id_seq)
        OR EXISTS (SELECT 1 FROM order_items)
);

SELECT setval(
    'inventory_log_id_seq',
    GREATEST(
        (SELECT last_value FROM inventory_log_id_seq),
        COALESCE((SELECT MAX(log_id) FROM inventory_log), 1)
    ),
    (SELECT is_called FROM inventory_log_id_seq)
        OR EXISTS (SELECT 1 FROM inventory_log)
);


-- ============================================================
-- 2. CONCURRENCY-SAFE ORDER PLACEMENT
-- ============================================================

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
    -- Reject missing, zero, or negative quantities.
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        RETURN QUERY
        SELECT FALSE, NULL::BIGINT, 'Invalid quantity'::TEXT;
        RETURN;
    END IF;

    -- Confirm that the customer exists.
    IF NOT EXISTS (
        SELECT 1
        FROM customers
        WHERE customer_id = p_customer_id
    ) THEN
        RETURN QUERY
        SELECT FALSE, NULL::BIGINT, 'Customer not found'::TEXT;
        RETURN;
    END IF;

    -- Deduct stock only when sufficient stock exists and the
    -- product has a valid positive price.
    --
    -- The conditional UPDATE is atomic. Concurrent requests
    -- cannot both purchase the same final unit.

    UPDATE products
    SET stock_quantity = stock_quantity - p_quantity
    WHERE product_id = p_product_id
      AND stock_quantity >= p_quantity
      AND price IS NOT NULL
      AND price > 0
    RETURNING price INTO v_price;

    IF NOT FOUND THEN
        RETURN QUERY
        SELECT
            FALSE,
            NULL::BIGINT,
            CASE
                WHEN NOT EXISTS (
                    SELECT 1
                    FROM products
                    WHERE product_id = p_product_id
                )
                THEN 'Product not found'::TEXT

                WHEN EXISTS (
                    SELECT 1
                    FROM products
                    WHERE product_id = p_product_id
                      AND (price IS NULL OR price <= 0)
                )
                THEN 'Invalid product price'::TEXT

                ELSE 'Out of stock'::TEXT
            END;
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

    -- Record the purchased product.
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

    -- Record the inventory movement for audit purposes.
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
        'Order #' || v_order_id
            || ': sale of ' || p_quantity || ' unit(s)'
    );

    RETURN QUERY
    SELECT
        TRUE,
        v_order_id::BIGINT,
        'Order placed successfully'::TEXT;
END;
$$;


-- ============================================================
-- 3. CONTROLLED STOCK ADJUSTMENTS
-- ============================================================

CREATE OR REPLACE FUNCTION adjust_stock(
    p_product_id BIGINT,
    p_change_qty INTEGER,
    p_reason TEXT,
    p_note TEXT DEFAULT NULL
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    new_stock INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_stock INTEGER;
    v_reason TEXT := LOWER(BTRIM(p_reason));
BEGIN
    -- Reject zero or missing adjustments.
    IF p_change_qty IS NULL OR p_change_qty = 0 THEN
        RETURN QUERY
        SELECT
            FALSE,
            'Quantity change must not be zero'::TEXT,
            NULL::INTEGER;
        RETURN;
    END IF;

    -- Restrict adjustments to supported reasons.
    IF v_reason IS NULL
       OR v_reason NOT IN ('restock', 'correction') THEN
        RETURN QUERY
        SELECT
            FALSE,
            'Reason must be restock or correction'::TEXT,
            NULL::INTEGER;
        RETURN;
    END IF;

    -- Require a meaningful explanation for every adjustment.
    IF p_note IS NULL OR BTRIM(p_note) = '' THEN
        RETURN QUERY
        SELECT
            FALSE,
            'A meaningful adjustment note is required'::TEXT,
            NULL::INTEGER;
        RETURN;
    END IF;

    -- Restocking must increase inventory.
    IF v_reason = 'restock' AND p_change_qty < 0 THEN
        RETURN QUERY
        SELECT
            FALSE,
            'Restock quantity must be positive'::TEXT,
            NULL::INTEGER;
        RETURN;
    END IF;

    -- Use BIGINT for the intermediate calculation so integer
    -- arithmetic cannot overflow before the range is checked.
    --
    -- The UPDATE remains atomic under concurrent adjustments.

    UPDATE products
    SET stock_quantity = (
        stock_quantity::BIGINT + p_change_qty
    )::INTEGER
    WHERE product_id = p_product_id
      AND stock_quantity::BIGINT + p_change_qty
          BETWEEN 0 AND 2147483647
    RETURNING stock_quantity INTO v_new_stock;

    IF NOT FOUND THEN
        RETURN QUERY
        SELECT
            FALSE,
            CASE
                WHEN NOT EXISTS (
                    SELECT 1
                    FROM products
                    WHERE product_id = p_product_id
                )
                THEN 'Product not found'::TEXT

                WHEN EXISTS (
                    SELECT 1
                    FROM products
                    WHERE product_id = p_product_id
                      AND stock_quantity IS NULL
                )
                THEN 'Current stock quantity is missing'::TEXT

                WHEN p_change_qty < 0
                THEN 'Insufficient stock for correction'::TEXT

                ELSE 'Adjustment would exceed the supported stock range'::TEXT
            END,
            NULL::INTEGER;
        RETURN;
    END IF;

    -- Record the successful stock adjustment.
    INSERT INTO inventory_log (
        product_id,
        change_qty,
        reason,
        created_at,
        note
    )
    VALUES (
        p_product_id::INTEGER,
        p_change_qty,
        v_reason,
        CURRENT_TIMESTAMP,
        BTRIM(p_note)
    );

    RETURN QUERY
    SELECT
        TRUE,
        'Stock adjusted successfully'::TEXT,
        v_new_stock;
END;
$$;


-- ============================================================
-- 4. RECURSIVE LOW-STOCK REPORTING
-- ============================================================

CREATE OR REPLACE FUNCTION low_stock_products(
    p_threshold INTEGER DEFAULT 5
)
RETURNS TABLE (
    product_id INTEGER,
    product_name TEXT,
    category_id INTEGER,
    category_path TEXT,
    category_depth INTEGER,
    stock_quantity INTEGER,
    category_cycle_detected BOOLEAN,
    missing_parent_detected BOOLEAN
)
LANGUAGE sql
STABLE
AS $$
    WITH RECURSIVE low_stock AS (
        -- Select products at or below the requested stock level.
        SELECT
            product_id,
            product_name,
            category_id,
            stock_quantity
        FROM products
        WHERE stock_quantity <= p_threshold
    ),

    category_walk AS (
        -- Begin at each product's assigned category.
        SELECT
            ls.product_id,
            c.category_id AS walk_category_id,
            c.category_name,
            c.parent_id,
            0 AS depth,
            ARRAY[c.category_id] AS visited
        FROM low_stock ls
        LEFT JOIN categories c
            ON c.category_id = ls.category_id

        UNION ALL

        -- Follow parent links upwards through the hierarchy.
        -- The visited array prevents infinite recursion if a cycle
        -- exists in the category relationships.
        SELECT
            cw.product_id,
            parent.category_id,
            parent.category_name,
            parent.parent_id,
            cw.depth + 1,
            cw.visited || parent.category_id
        FROM category_walk cw
        JOIN categories parent
            ON parent.category_id = cw.parent_id
        WHERE cw.parent_id IS NOT NULL
          AND NOT (cw.parent_id = ANY(cw.visited))
    )

    SELECT
        ls.product_id,
        ls.product_name,
        ls.category_id,

        -- Display the path from the highest reachable parent
        -- down to the product's assigned category.
        COALESCE(
            STRING_AGG(
                cw.category_name,
                ' > ' ORDER BY cw.depth DESC
            ),
            'Uncategorized'
        )::TEXT AS category_path,

        -- A missing or unassigned category has depth zero.
        CASE
            WHEN ls.category_id IS NULL
              OR NOT EXISTS (
                  SELECT 1
                  FROM categories c
                  WHERE c.category_id = ls.category_id
              )
            THEN 0
            ELSE COALESCE(MAX(cw.depth) + 1, 0)
        END::INTEGER AS category_depth,

        ls.stock_quantity,

        -- Detect a parent link that points back to an already
        -- visited category.
        COALESCE(
            BOOL_OR(cw.parent_id = ANY(cw.visited)),
            FALSE
        ) AS category_cycle_detected,

        -- Detect a missing assigned category or a missing parent.
        (
            ls.category_id IS NOT NULL
            AND NOT EXISTS (
                SELECT 1
                FROM categories c
                WHERE c.category_id = ls.category_id
            )
        )
        OR COALESCE(
            BOOL_OR(
                cw.parent_id IS NOT NULL
                AND NOT EXISTS (
                    SELECT 1
                    FROM categories missing
                    WHERE missing.category_id = cw.parent_id
                )
            ),
            FALSE
        ) AS missing_parent_detected

    FROM low_stock ls
    LEFT JOIN category_walk cw
        ON cw.product_id = ls.product_id

    GROUP BY
        ls.product_id,
        ls.product_name,
        ls.category_id,
        ls.stock_quantity

    ORDER BY
        ls.stock_quantity,
        ls.product_id;
$$;
