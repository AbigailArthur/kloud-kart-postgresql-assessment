-- FILE 02: DUPLICATE RECORD CHECKS
-- Normalization is used to identify possible duplicates.
-- Shared names or phone numbers do not automatically prove
-- that two customer records belong to the same person.

\echo '1. Duplicate customer email groups'

SELECT
    LOWER(TRIM(email)) AS normalized_email,
    COUNT(*) AS occurrences
FROM customers
WHERE email IS NOT NULL
  AND TRIM(email) <> ''
GROUP BY LOWER(TRIM(email))
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


\echo '2. Count duplicate customer email groups'

SELECT
    COUNT(*) AS duplicate_email_groups
FROM (
    SELECT LOWER(TRIM(email))
    FROM customers
    WHERE email IS NOT NULL
      AND TRIM(email) <> ''
    GROUP BY LOWER(TRIM(email))
    HAVING COUNT(*) > 1
) AS duplicates;


\echo '3. Customer records sharing duplicate emails'

SELECT
    customer_id,
    full_name,
    email,
    LOWER(TRIM(email)) AS normalized_email
FROM customers
WHERE email IS NOT NULL
  AND TRIM(email) <> ''
  AND LOWER(TRIM(email)) IN (
      SELECT LOWER(TRIM(email))
      FROM customers
      WHERE email IS NOT NULL
        AND TRIM(email) <> ''
      GROUP BY LOWER(TRIM(email))
      HAVING COUNT(*) > 1
  )
ORDER BY normalized_email, customer_id;


\echo '4. Repeated product names within the same category'

SELECT
    LOWER(TRIM(product_name)) AS normalized_product_name,
    category_id,
    COUNT(*) AS occurrences
FROM products
WHERE product_name IS NOT NULL
  AND TRIM(product_name) <> ''
GROUP BY LOWER(TRIM(product_name)), category_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


\echo '5. Repeated products within the same order'

SELECT
    order_id,
    product_id,
    COUNT(*) AS occurrences
FROM order_items
GROUP BY order_id, product_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


\echo '6. Possible duplicate customer names'

SELECT
    LOWER(TRIM(full_name)) AS normalized_name,
    COUNT(*) AS occurrences
FROM customers
WHERE full_name IS NOT NULL
  AND TRIM(full_name) <> ''
GROUP BY LOWER(TRIM(full_name))
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


\echo '7. Possible duplicate customer phone numbers'

SELECT
    REGEXP_REPLACE(phone, '[^0-9]', '', 'g') AS normalized_phone,
    COUNT(*) AS occurrences
FROM customers
WHERE phone IS NOT NULL
  AND TRIM(phone) <> ''
GROUP BY REGEXP_REPLACE(phone, '[^0-9]', '', 'g')
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;
