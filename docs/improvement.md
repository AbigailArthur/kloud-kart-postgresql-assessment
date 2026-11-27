
# Additional Improvement: Reusable SQL Data Profiling Toolkit

## Overview

Beyond the core database implementation, I developed a reusable SQL data-profiling toolkit to help Kloud Kart identify data-quality issues.

Instead of relying on one-time investigations, I organised the profiling queries into six independent SQL scripts under `sql/profiling/`.

The scripts can be rerun manually after loading new data, providing a repeatable approach to assessing data quality.

## What the Improvement Includes

The toolkit contains checks for:

1. Missing and NULL values, including blank text fields.
2. Potential duplicates involving normalized customer emails, repeated product names within categories, and repeated product entries within orders.
3. Referential integrity violations.
4. Inconsistent prices, quantities, stock levels, and order totals.
5. Category hierarchy issues, including missing parent references and circular relationships.
6. Unusual order statuses, missing inventory notes, and future-dated records.

## Business Value

The toolkit helps Kloud Kart to:

- Identify data problems before relying on the data for business reporting.
- Investigate issues affecting inventory, orders, and customer records.
- Reduce dependence on manual, one-time SQL investigations.
- Give future data engineers a consistent starting point for data-quality assessments.
- Repeat the same checks after subsequent data loads.

## Evidence and Validation

All six profiling scripts were executed successfully against the Kloud Kart PostgreSQL database.

The checks identified:

- 37 products without category assignments.
- 210 orders referencing nonexistent customers.
- 692 order items referencing nonexistent orders.
- 120 inventory movements referencing nonexistent products.
- 281,927 of 282,352 inventory records with missing notes (approximately 99.85%).
- A circular relationship involving categories 9001 and 9002.

These results demonstrate the toolkit's ability to expose data-quality issues that could affect operational decisions and reporting.

## Limitation

The toolkit identifies and reports data-quality issues; it does not automatically correct records, run on a schedule, or maintain historical monitoring metrics.

Any data corrections should be reviewed against source records and approved business rules before being applied.

## Conclusion

The reusable profiling toolkit extends the project beyond a one-time database assessment by providing Kloud Kart with a practical set of SQL checks that can be rerun manually as new data becomes available.
