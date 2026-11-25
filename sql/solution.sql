
-- =========================================================
-- KLOUD KART POSTGRESQL ASSESSMENT
-- Complete database solution
-- =========================================================

-- SECTION 1: SAFE ID GENERATION
CREATE SEQUENCE IF NOT EXISTS orders_id_seq AS INTEGER;
CREATE SEQUENCE IF NOT EXISTS order_items_id_seq AS INTEGER;
CREATE SEQUENCE IF NOT EXISTS inventory_log_id_seq AS INTEGER;

ALTER TABLE orders
    ALTER COLUMN order_id
    SET DEFAULT nextval('orders_id_seq');

ALTER TABLE order_items
    ALTER COLUMN order_item_id
    SET DEFAULT nextval('order_items_id_seq');

ALTER TABLE inventory_log
    ALTER COLUMN log_id
    SET DEFAULT nextval('inventory_log_id_seq');

SELECT setval(
    'orders_id_seq',
    GREATEST(
        (SELECT last_value FROM orders_id_seq),
        COALESCE((SELECT MAX(order_id) FROM orders), 0)
    ),
    TRUE
);

SELECT setval(
    'order_items_id_seq',
    GREATEST(
        (SELECT last_value FROM order_items_id_seq),
        COALESCE((SELECT MAX(order_item_id) FROM order_items), 0)
    ),
    TRUE
);

SELECT setval(
    'inventory_log_id_seq',
    GREATEST(
        (SELECT last_value FROM inventory_log_id_seq),
        COALESCE((SELECT MAX(log_id) FROM inventory_log), 0)
    ),
    TRUE
);
-- SECTION 2: CONCURRENCY-SAFE ORDER PLACEMENT
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
LANGUAGE PLPGSQL
AS $$
DECLARE
    v_price NUMERIC(12,2);
    v_order_id INTEGER;
BEGIN
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        RETURN QUERY
        SELECT FALSE, NULL::BIGINT, 'Invalid quantity'::TEXT;
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM customers
        WHERE customer_id = p_customer_id
    ) THEN
        RETURN QUERY
        SELECT FALSE, NULL::BIGINT, 'Customer not found'::TEXT;
        RETURN;
    END IF;

    UPDATE products
    SET stock_quantity = stock_quantity - p_quantity
    WHERE product_id = p_product_id
      AND stock_quantity >= p_quantity
    RETURNING price INTO v_price;

    IF NOT FOUND THEN
        RETURN QUERY
        SELECT FALSE, NULL::BIGINT, 'Out of stock'::TEXT;
        RETURN;
    END IF;

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
    SELECT TRUE, v_order_id::BIGINT,
           'Order placed successfully'::TEXT;
END;
$$;
-- SECTION 3: REPORTING PERFORMANCE INDEX
CREATE INDEX IF NOT EXISTS idx_orders_completed_report
ON orders (order_date, customer_id)
INCLUDE (total_amount)
WHERE LOWER(BTRIM(status)) IN ('completed', 'complete');
-- SECTION 4: CONTROLLED STOCK ADJUSTMENTS
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
LANGUAGE PLPGSQL
AS $$
DECLARE
    v_new_stock INTEGER;
    v_reason TEXT;
BEGIN
    v_reason := LOWER(BTRIM(p_reason));

    IF p_change_qty IS NULL OR p_change_qty = 0 THEN
        RETURN QUERY
        SELECT FALSE, 'Quantity change must not be zero'::TEXT,
                     NULL::INTEGER;
        RETURN;
    END IF;

    IF v_reason IS NULL
       OR v_reason NOT IN ('restock', 'correction') THEN
        RETURN QUERY
        SELECT FALSE, 'Reason must be restock or correction'::TEXT,
                     NULL::INTEGER;
        RETURN;
    END IF;

    IF v_reason = 'restock' AND p_change_qty < 0 THEN
        RETURN QUERY
        SELECT FALSE, 'Restock quantity must be positive'::TEXT,
                     NULL::INTEGER;
        RETURN;
    END IF;

    UPDATE products
    SET stock_quantity = stock_quantity + p_change_qty
    WHERE product_id = p_product_id
      AND stock_quantity + p_change_qty >= 0
    RETURNING products.stock_quantity INTO v_new_stock;

    IF NOT FOUND THEN
        IF EXISTS (
            SELECT 1
            FROM products
            WHERE product_id = p_product_id
        ) THEN
            RETURN QUERY
            SELECT FALSE, 'Insufficient stock for correction'::TEXT,
                         NULL::INTEGER;
        ELSE
            RETURN QUERY
            SELECT FALSE, 'Product not found'::TEXT, NULL::INTEGER;
        END IF;

        RETURN;
    END IF;

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
        p_note
    );

    RETURN QUERY
    SELECT TRUE, 'Stock adjusted successfully'::TEXT, v_new_stock;
END;
$$;
-- SECTION 5: RECURSIVE LOW-STOCK VISIBILITY
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
LANGUAGE SQL
STABLE
AS $$
    WITH RECURSIVE low_stock AS (
        SELECT
            p.product_id,
            p.product_name,
            p.category_id,
            p.stock_quantity
        FROM products p
        WHERE p.stock_quantity <= p_threshold
    ),

    category_walk AS (
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

        COALESCE(
            STRING_AGG(
                cw.category_name,
                ' > ' ORDER BY cw.depth DESC
            ),
            'Uncategorized'
        )::TEXT AS category_path,

        CASE
            WHEN ls.category_id IS NULL THEN 0
            ELSE COALESCE(MAX(cw.depth) + 1, 0)
        END::INTEGER AS category_depth,

        ls.stock_quantity,

        COALESCE(
            BOOL_OR(cw.parent_id = ANY(cw.visited)),
            FALSE
        ) AS category_cycle_detected,

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
