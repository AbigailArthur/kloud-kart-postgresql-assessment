# Client Memo: Kloud Kart Assessment

**To:** Nana  
**Subject:** Improving Inventory Management and Customer Reporting

## Overview

The assessment reviewed Kloud Kart's inventory, orders, customer records, and reporting processes. It identified data-quality problems that could affect stock availability, order integrity, financial reconciliation, and business decisions.

Database improvements were developed and tested against the supplied dataset using PostgreSQL, without requiring additional infrastructure.

## Key Findings

- **Stock accuracy:** 14 products have negative stock quantities, and 120 inventory movements reference nonexistent products.
- **Order integrity:** 692 order items reference nonexistent orders, while 210 orders reference nonexistent customers.
- **Sales reconciliation:** 2,279 fully priced orders have discrepancies between their stored totals and calculated item values. Another 147 orders contain missing unit prices and cannot be reliably reconciled.
- **Inventory record keeping:** 281,927 of 282,352 inventory records (99.85%) have missing notes, limiting the ability to explain stock movements.
- **Product categories:** Three categories are unreachable from the hierarchy roots. The defects include a missing-parent reference and a circular relationship.

These findings represent risks requiring investigation. They do not, by themselves, establish financial losses or prove that every flagged record is incorrect.

## Improvements Developed

1. **Safer purchasing:** Implemented a database purchasing function that uses atomic stock updates to prevent overselling when customers compete for limited stock.
2. **Stock adjustment tracking:** Implemented a controlled stock-adjustment function that updates stock quantities and records inventory movements with their reasons.
3. **Low-stock visibility:** Developed a report that identifies low-stock products and includes their category paths, including nested categories.
4. **Customer reporting:** Developed a Monday customer report covering spending, order counts, monthly spending trends, cumulative spending, and the top 100 customers.

The customer report returned 310 monthly rows and completed in under one second during local testing. This is a measured test result, not a guarantee of production performance under peak traffic.

## Recommendations

1. Reconcile orphaned order items and orders with missing customer references against source transaction records.
2. Investigate order total discrepancies and missing unit prices before making financial corrections.
3. Review negative stock balances and invalid inventory references against the inventory movement history.
4. Require meaningful notes for future stock adjustments and other operationally important inventory movements.
5. Approve a standard set of order statuses and consistent naming rules.
6. Repair the category hierarchy and assign categories to the 37 uncategorized products.
7. Review potential duplicate customer records and future-dated transactions before changing or deleting data.

## Limitations

The database improvements do not automatically correct historical data. Existing records require investigation and approved business rules before corrections are applied.

Some historical inventory movements lack sufficient information to connect them to specific orders. Order total differences may also reflect discounts, taxes, shipping charges, or adjustments not represented in the supplied tables.

The performance results were obtained in a local test environment. Production behaviour under realistic flash-sale traffic remains to be verified.

## Conclusion

The assessment provides Kloud Kart with improved database-level controls for purchasing and stock adjustments, better low-stock visibility, and a customer reporting solution.

The next priority is to investigate the existing data-quality issues and introduce consistent operational procedures. Combining these improvements with verified source records will help Nana make more reliable inventory and customer-management decisions.