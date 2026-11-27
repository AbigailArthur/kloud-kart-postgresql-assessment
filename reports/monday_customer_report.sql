WITH monthly AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', order_date) AS report_month,
        SUM(total_amount) AS monthly_spend,
        COUNT(*) AS monthly_order_count
    FROM orders
    WHERE LOWER(BTRIM(status)) IN ('completed', 'complete')
      AND order_date >= CURRENT_DATE - INTERVAL '12 months'
      AND order_date < CURRENT_DATE + INTERVAL '1 day'
    GROUP BY customer_id, DATE_TRUNC('month', order_date)
),
totals AS (
    SELECT
        customer_id,
        SUM(monthly_spend) AS total_spent,
        SUM(monthly_order_count) AS order_count
    FROM monthly
    GROUP BY customer_id
),
ranked AS (
    SELECT
        customer_id,
        total_spent,
        order_count,
        ROW_NUMBER() OVER (
            ORDER BY total_spent DESC, customer_id
        ) AS customer_rank
    FROM totals
)
SELECT
    m.customer_id,
    r.total_spent,
    r.order_count,
    m.report_month,
    m.monthly_spend,
    SUM(m.monthly_spend) OVER (
        PARTITION BY m.customer_id
        ORDER BY m.report_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_spend,
    r.customer_rank
FROM monthly m
JOIN ranked r USING (customer_id)
WHERE r.customer_rank <= 100
ORDER BY r.customer_rank, m.report_month;
