# Kloud Kart - Data Quality Findings

## 1. Executive Summary

The assessment identified data quality issues affecting inventory accuracy, order integrity, customer reporting, and category management.

Key findings include:
- 14 products have negative stock quantities.
- 120 inventory movements reference nonexistent products.
- 692 order items reference nonexistent orders.
- 210 orders reference nonexistent customers.
- 2,398 orders have totals that differ from their calculated item values by more than 0.01.
- Inventory movement notes are missing in 99.98% of records.
- The category hierarchy contains an orphan reference and a circular relationship.
- Order statuses contain inconsistent labels and formatting.

## 2. Ranked Data Quality Findings

| Priority | Finding and evidence | Business impact |
|---|---|---|
| 1 - High | **Negative stock:** 14 products have stock below zero. Detected by checking `stock_quantity < 0`. | Unreliable stock availability and potential fulfilment problems. |
| 2 - High | **Broken order references:** 692 order-item records reference nonexistent orders; 210 orders reference nonexistent customers. Detected using unmatched `LEFT JOIN` records. | Incomplete order records and unattributable customer spending. |
| 3 - High | **Order total discrepancies:** 2,398 orders differ from calculated item totals by more than 0.01. Compared `total_amount` with the sum of quantity multiplied by unit price. | Customer spending and revenue reports may be inaccurate. Differences require investigation, not automatic classification as losses. |
| 4 - High | **Invalid inventory references:** 120 inventory movements reference nonexistent products. Detected using a `LEFT JOIN` to products. | Weakens stock movement traceability. |
| 5 - Medium | **Missing inventory notes:** 282,292 of 282,352 records (99.98%) have blank or missing notes. | Makes stock changes harder to explain and investigate. |
| 6 - Medium | **Inconsistent statuses:** 15 raw status variations represent seven normalized groups, including `complete`/`completed` and `cancelled`/`canceled`. | Can cause inconsistent reporting and order classification. |
| 7 - Medium | **Category hierarchy issues:** One orphan parent reference and a two-category cycle exist; only 91 of 94 categories are reachable from roots. | Can affect category navigation and hierarchical reporting. |
| 8 - Other | **Additional concerns:** 37 products have no category; 533 duplicate normalized email groups exist; 16 orders and 33 inventory movements have future timestamps relative to 25 November 2026. | Affects product classification, customer identification, and time-based reporting. |

Duplicate email groups require investigation; customers should not be merged automatically. Future timestamps should also be verified against the source system.

## 3. Reporting Performance Findings

The Monday customer report was tested using the full dataset of 159,384 orders and 336,559 order items.

| Test | Execution time |
|---|---:|
| Baseline customer aggregation | 232.696 ms |
| Complete report before index | 408.805 ms |
| Complete report with partial covering index | 445.197 ms |
| Complete report with `work_mem = 32MB` | 520.793 ms |

The report returned 310 monthly rows for the top 100 customers. All complete-report tests finished in under one second. The index enabled an index-only scan but did not improve total execution time. Increasing `work_mem` removed temporary-file spilling but also did not improve total execution time.

These are local test measurements, not production performance guarantees.