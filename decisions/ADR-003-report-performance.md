# ADR-003: Monday Customer Report Performance

**Status:** Accepted

## Context
Kloud Kart needs a Monday customer spending report showing total spend, order count, monthly spending over the trailing 12 months, running totals, and the top 100 customers.

The report must run efficiently on the existing PostgreSQL database.

## Options considered
- **Repeated aggregations:** Simpler to write but can repeat expensive calculations.
- **Monthly aggregation with window functions:** Calculates monthly totals once and derives customer totals, rankings, and running spend.
- **Additional indexing:** Can reduce data access but requires testing to confirm an overall performance benefit.

## Decision
Use a monthly aggregation CTE, followed by customer totals, ranking, and window functions. Add a partial covering index on completed orders to support the report query.

The report treats `complete` and `completed` as equivalent and uses the trailing 12-month date window.

## Consequences
- Produces the required customer and monthly spending metrics in one query.
- Avoids repeating the monthly aggregation.
- The index enables an index-only scan, but testing did not show a reduction in total execution time.
- Performance depends on data volume, database resources, and data quality.

## Validation
Using 159,384 orders and 336,559 order items:
- Baseline aggregation: 232.696 ms.
- Complete report before index: 408.805 ms.
- Complete report with index: 445.197 ms.
- Complete report with `work_mem = 32MB`: 520.793 ms.
- Returned 310 monthly rows for the top 100 customers.

All complete-report tests finished in under one second. These are local test results, not production guarantees.