-- FILE 05: CATEGORY HIERARCHY CHECKS

-- 1. List products without a category.
SELECT
    product_id,
    product_name
FROM products
WHERE category_id IS NULL
ORDER BY product_id;

-- 2. Count products without a category.
SELECT
    COUNT(*) AS uncategorized_products
FROM products
WHERE category_id IS NULL;

-- 3. Find categories referencing a parent that does not exist.
SELECT
    child.category_id,
    child.category_name,
    child.parent_id
FROM categories AS child
LEFT JOIN categories AS parent
    ON child.parent_id = parent.category_id
WHERE child.parent_id IS NOT NULL
  AND parent.category_id IS NULL
ORDER BY child.category_id;

-- 4. List root categories.
SELECT
    category_id,
    category_name
FROM categories
WHERE parent_id IS NULL
ORDER BY category_id;

-- 5. Find categories that reference themselves.
SELECT
    category_id,
    category_name,
    parent_id
FROM categories
WHERE category_id = parent_id
ORDER BY category_id;

-- 6. Count categories reachable from root categories.
WITH RECURSIVE category_tree AS (
    SELECT category_id, parent_id
    FROM categories
    WHERE parent_id IS NULL

    UNION

    SELECT child.category_id, child.parent_id
    FROM categories AS child
    INNER JOIN category_tree AS tree
        ON child.parent_id = tree.category_id
)
SELECT
    (SELECT COUNT(*) FROM categories) AS total_categories,
    COUNT(DISTINCT category_id) AS reachable_from_roots,
    (SELECT COUNT(*) FROM categories)
        - COUNT(DISTINCT category_id) AS unreachable_from_roots
FROM category_tree;

-- 7. Detect circular parent-child relationships.
WITH RECURSIVE category_walk AS (
    SELECT
        category_id AS start_id,
        category_id,
        parent_id,
        ARRAY[category_id] AS visited,
        FALSE AS has_cycle
    FROM categories

    UNION ALL

    SELECT
        walk.start_id,
        parent.category_id,
        parent.parent_id,
        walk.visited || parent.category_id,
        parent.category_id = ANY(walk.visited)
    FROM category_walk AS walk
    INNER JOIN categories AS parent
        ON walk.parent_id = parent.category_id
    WHERE walk.parent_id IS NOT NULL
      AND NOT walk.has_cycle
)
SELECT DISTINCT
    start_id AS category_id_with_cycle
FROM category_walk
WHERE has_cycle
ORDER BY start_id;
