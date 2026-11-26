-- 1. Find duplicate customer emails
SELECT
    LOWER(TRIM(email)) AS normalized_email,
    COUNT(*) AS occurrences
FROM customers
WHERE email IS NOT NULL
  AND TRIM(email) <> ''
GROUP BY LOWER(TRIM(email))
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- 2. Count how many email groups are duplicated
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


-- 3. Display customer records sharing duplicate emails
SELECT
    customer_id,
    full_name,
    email,
    LOWER(TRIM(email)) AS normalized_email
FROM customers
WHERE LOWER(TRIM(email)) IN (
    SELECT LOWER(TRIM(email))
    FROM customers
    WHERE email IS NOT NULL
      AND TRIM(email) <> ''
    GROUP BY LOWER(TRIM(email))
    HAVING COUNT(*) > 1
)
ORDER BY normalized_email, customer_id;


-- 4. Check for repeated product names within the same category
SELECT
    LOWER(TRIM(product_name)) AS normalized_product_name,
    category_id,
    COUNT(*) AS occurrences
FROM products
WHERE product_name IS NOT NULL
GROUP BY LOWER(TRIM(product_name)), category_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;


-- 5. Check for repeated products within the same order
SELECT
    order_id,
    product_id,
    COUNT(*) AS occurrences
FROM order_items
GROUP BY order_id, product_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;
