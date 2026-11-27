-- Load Kloud Kart's CSV extract.
--
-- Run this script after sql/schema.sql and before sql/solution.sql.
--
-- The CSV files are read by the PostgreSQL client using \copy.
-- When running psql inside Docker, copy the data directory into the
-- container and run psql from the directory containing the data folder.
--
-- Example Docker working directory: /workspace
-- Example CSV directory: /workspace/data
--
-- The schema script drops and recreates the project tables.
-- Run it only against a fresh or disposable assessment database.

\set ON_ERROR_STOP on
\timing on

\copy categories    (category_id, category_name, parent_id)                                   FROM 'data/categories.csv'    WITH (FORMAT csv, HEADER true, NULL '')
\copy products      (product_id, product_name, category_id, price, stock_quantity, created_at) FROM 'data/products.csv'      WITH (FORMAT csv, HEADER true, NULL '')
\copy customers     (customer_id, full_name, email, phone, city, registered_at)               FROM 'data/customers.csv'     WITH (FORMAT csv, HEADER true, NULL '')
\copy orders        (order_id, customer_id, order_date, status, total_amount)                 FROM 'data/orders.csv'        WITH (FORMAT csv, HEADER true, NULL '')
\copy order_items   (order_item_id, order_id, product_id, quantity, unit_price)               FROM 'data/order_items.csv'   WITH (FORMAT csv, HEADER true, NULL '')
\copy inventory_log (log_id, product_id, change_qty, reason, created_at, note)                FROM 'data/inventory_log.csv' WITH (FORMAT csv, HEADER true, NULL '')

ANALYZE;

SELECT 'categories'    AS table_name, COUNT(*) FROM categories
UNION ALL SELECT 'products',      COUNT(*) FROM products
UNION ALL SELECT 'customers',     COUNT(*) FROM customers
UNION ALL SELECT 'orders',        COUNT(*) FROM orders
UNION ALL SELECT 'order_items',   COUNT(*) FROM order_items
UNION ALL SELECT 'inventory_log', COUNT(*) FROM inventory_log
ORDER BY 1;
