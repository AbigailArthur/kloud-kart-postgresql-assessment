# Kloud Kart - Data Quality Findings

## 1. Executive Summary

The assessment identified data quality issues that could affect inventory accuracy, order integrity, financial reconciliation, customer reporting, and category management.

The most significant findings are:

- **14 products have negative stock quantities**, creating potential inventory availability and fulfilment risks.
- **692 order items reference nonexistent orders**, while 210 orders reference nonexistent customers.
- **2,279 fully priced orders have discrepancies** between their stored totals and calculated item values. An additional 147 orders contain missing unit prices and cannot be reliably reconciled.
- **120 inventory movements reference nonexistent products.**
- **281,927 of 282,352 inventory records (99.85%) have missing notes**, weakening the inventory audit trail.
- The category hierarchy has three unreachable categories, including a missing-parent reference and a circular relationship.
- Customer email duplication, inconsistent order statuses, uncategorized products, and future-dated records require further investigation.

These findings identify potential business and reporting risks. They do not automatically establish financial losses or prove that every flagged record is erroneous.

## 2. Ranked Data Quality Findings

The priorities below reflect potential business impact and the need for investigation, rather than record counts alone.

| Priority | Finding and evidence | Business impact and recommended response |
|---|---|---|
| 1 - Critical | **Order integrity:** 692 order-item records reference nonexistent orders. These records contain 968 units with a recorded value of 826,327.80. Another 210 orders reference nonexistent customers, with stored totals of 665,180.61. | Order histories, customer attribution, and financial reporting may be incomplete. Reconcile the orphan records against source transactions before correcting references. The two recorded monetary amounts describe different groups of records and should not be added together or treated as confirmed financial losses. |
| 2 - High | **Order total discrepancies:** 2,279 fully priced orders have stored totals differing from calculated item values by more than 0.01. These represent approximately 1.43% of 159,237 fully priced orders. Their combined absolute difference is 3,760,997.98. An additional 147 orders contain missing unit prices. | Financial and customer reports may be unreliable. Validate discounts, taxes, shipping, adjustments, and source transaction rules before changing stored totals. The differences are not confirmed losses. |
| 3 - High | **Negative stock:** 14 products have negative stock quantities. | Stock availability may be unreliable, creating potential overselling and fulfilment problems. Investigate the affected products against inventory movements and sales records before adjusting balances. |
| 4 - High | **Invalid inventory references:** 120 inventory movements reference nonexistent products. | Stock movement history cannot be fully reconciled to the product catalogue. Investigate the affected product references and source records. |
| 5 - High | **Missing inventory audit notes:** 281,927 of 282,352 inventory records (99.85%) have missing notes. All records associated with the sale, restock, return, damage, and stock_take reasons have missing notes. | Staff may struggle to explain or audit inventory changes. Introduce mandatory, meaningful notes for adjustments and other operationally important movements. |
| 6 - Medium | **Inconsistent order statuses:** 15 distinct raw status values reduce to seven groups after trimming whitespace and normalizing case. Variants include `complete`/`completed` and `canceled`/`cancelled`. | Reports filtering for one spelling may omit orders represented by another. Establish a business-approved canonical status mapping before standardizing existing records. |
| 7 - Medium | **Category hierarchy defects:** Of 94 categories, 91 are reachable from roots and three are unreachable. Category 9003 (`Clearance`) references nonexistent parent 8999. Categories 9001 and 9002 form a circular relationship. | Recursive reports and category navigation may omit or misclassify categories. Repair the missing parent and cycle after confirming the intended hierarchy. |
| 8 - Medium | **Duplicate customer emails:** 533 normalized email groups contain 535 excess customer records. | Customer counts and order histories may be duplicated. Verify customer identity before merging accounts. |
| 9 - Medium | **Uncategorized products:** 37 products have no category assignment. | Product discovery and category-based reporting may be incomplete. Assign categories after reviewing the product catalogue. |
| 10 - Investigate | **Future-dated records:** Using 27 November 2026 as the assessment reference date, 15 orders and 33 inventory movements have timestamps on or after that date. The earliest observed date after the reference date is 4 December 2026. | Future dates may distort time-based reports if they are not scheduled records. Confirm whether they are intentional or incorrect source data. |

### Additional observations

- There are 616 repeated product groups within orders, affecting 615 orders and producing 617 excess rows. These may represent legitimate separate order lines; they must not be deleted without validation.
- There are 400 repeated product-name groups within categories, representing 429 excess product records. Matching names alone do not establish that products are identical.
- 152 order-item records have zero or negative unit prices. These are separate from the 148 records with missing unit prices and should be investigated independently.
- 90 inventory records have zero quantity changes. All are recorded as `stock_take`; these may be legitimate audit events rather than errors.

## 3. Order Total Reconciliation

The reconciliation compared each order's stored `total_amount` with the sum of `quantity x unit_price` for its order items, using a tolerance of 0.01.

Orders containing at least one missing unit price were excluded from the fully priced comparison to avoid calculating incomplete totals.

| Measure | Result |
|---|---:|
| Total orders | 159,384 |
| Fully priced orders | 159,237 |
| Fully priced orders with discrepancies | 2,279 |
| Orders excluded due to missing unit prices | 147 |
| Discrepant orders with stored totals higher than calculated totals | 938 |
| Discrepant orders with stored totals lower than calculated totals | 1,341 |
| Combined absolute difference | 3,760,997.98 |
| Net difference (stored minus calculated) | -2,670,101.54 |
| Largest absolute difference | 873,325.30 |

The discrepancies require source-level validation. Differences could reflect missing business rules such as discounts, taxes, shipping charges, or adjustments. They should not be automatically classified as revenue losses.

## 4. Reporting Performance Findings

The Monday customer report was tested using the full dataset of 159,384 orders and 336,559 order items.

| Test | Execution time |
|---|---:|
| Baseline customer aggregation | 232.696 ms |
| Complete report before index | 408.805 ms |
| Complete report with partial covering index | 445.197 ms |
| Complete report with `work_mem = 32MB` | 520.793 ms |

The report returned 310 monthly rows for the top 100 customers. All complete-report tests finished in under one second.

The partial covering index enabled an index-only scan but did not improve total execution time. Increasing `work_mem` removed temporary-file spilling but also did not improve total execution time.

Therefore, neither change is presented as a proven performance improvement. The baseline complete-report execution was faster in these tests.

These measurements are local test results, not production performance guarantees. Production performance should be monitored under realistic concurrent workloads and larger flash-sale volumes.

## 5. Recommended Investigation Order

1. Reconcile orphaned order items and orders with missing customer references.
2. Investigate order total discrepancies and missing unit prices against source transactions.
3. Review negative stock balances and invalid inventory product references.
4. Improve inventory movement documentation and auditability.
5. Approve canonical order status definitions and mapping rules.
6. Repair category hierarchy defects and assign missing product categories.
7. Investigate duplicate customer accounts and repeated catalogue entries.
8. Validate future-dated records against the source system.

## 6. Limitations and Interpretation

This assessment identifies anomalies and integrity problems in the supplied dataset. It does not establish that every anomaly represents an operational error or financial loss.

In particular:

- Repeated order lines may be legitimate.
- Duplicate emails may belong to the same customer or to different people sharing an address.
- Future-dated records may be intentional.
- Order total discrepancies may reflect business adjustments not represented in the supplied tables.
- Negative stock balances require reconciliation against the complete inventory and transaction history.

Corrections should therefore be supported by source records and approved business rules rather than automatic deletion or blanket updates.
