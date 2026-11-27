# ADR-003: Monday Customer Report Performance

**Status:** Accepted

## Context

Kloud Kart requires a Monday customer spending report containing:

- Total customer spending.
- Order counts.
- Monthly spending over the trailing 12 months.
- Running monthly spending totals.
- The top 100 customers.

The report must operate against the existing PostgreSQL database without relying on unnecessary infrastructure or repeated calculations.

## Options Considered

1. **Repeated aggregations:** Rejected because independently calculating customer totals, monthly spending, and rankings can scan and aggregate the same underlying data multiple times. This increases query work and makes the reporting logic harder to maintain.
2. **Monthly aggregation with window functions:** Selected because monthly spending can be calculated once and reused to derive customer totals, rankings, and running totals. PostgreSQL window functions provide these calculations without requiring separate repeated aggregations.
3. **Additional indexing:** Considered as a way to reduce data access. However, an index must be evaluated using complete-query execution time, not merely whether PostgreSQL uses it.

## Decision

Implement the report using a monthly aggregation CTE followed by customer-level aggregation, ranking, and window functions.

The report:

- Uses a trailing 12-month date window.
- Treats `complete` and `completed` as equivalent completed-order statuses.
- Calculates customer totals and monthly spending.
- Uses window functions to derive running totals and customer rankings.
- Returns the top 100 customers and their monthly reporting rows.

A partial covering index on completed orders was tested but not retained because it did not improve total execution time.

## Consequences and Trade-offs

**Benefits:**

- Avoids repeating the monthly aggregation.
- Keeps reporting calculations in PostgreSQL.
- Produces customer-level and monthly metrics in one report query.
- Benchmarking confirmed that the index enabled an index-only scan, but this did not translate into faster complete-report execution.

**Costs and risks:**

- The index did not reduce total execution time in the measured tests.
- Maintaining an additional index consumes storage and adds work to relevant data modifications.
- The index should not be described as a proven performance improvement.
- Report performance will depend on data volume, database resources, data distribution, and concurrent workloads.

The index is retained in the current implementation, but its continued value should be reviewed using production measurements. If it provides no operational benefit, removing it may reduce unnecessary index-maintenance overhead.

## Cost if the Decision Is Wrong

If the reporting approach becomes inefficient as data volume grows, customer reports could take longer to complete and delay business decisions. Retaining ineffective indexes could also increase storage and maintenance overhead without improving report performance.
## Validation

Testing used 159,384 orders and 336,559 order items.

| Test | Execution time |
|---|---:|
| Baseline customer aggregation | 232.696 ms |
| Complete report before index | 408.805 ms |
| Complete report with partial covering index | 445.197 ms |
| Complete report with `work_mem = 32MB` | 520.793 ms |

The complete report returned 310 monthly rows for the top 100 customers.

All complete-report tests finished in under one second.

The index enabled an index-only scan but did not improve total execution time. Increasing `work_mem` removed temporary-file spilling but also did not improve total runtime.

These results are local measurements, not production performance guarantees. Further testing under realistic concurrent workloads and larger flash-sale volumes is required.

## Rejected Alternative and Future Consideration

Repeated independent aggregations would be easier to write initially, but could create unnecessary work as the dataset grows.

A materialized reporting table could reduce repeated computation for scheduled reports, but would introduce refresh and data-freshness considerations. It is not justified by the current sub-second test results.

The current CTE and window-function approach is therefore retained, with future indexing or materialization decisions guided by measured production performance.
