# Kloud Kart PostgreSQL Assessment

A PostgreSQL database engineering project focused on building, validating, and improving the data operations of a fictional e-commerce business, Kloud Kart.

## Project Overview

This project works with an e-commerce dataset containing customers, products, categories, orders, order items, and inventory records.

The goal is to establish a reliable PostgreSQL database, investigate data-quality issues, implement essential database operations, and support customer-spending analysis.

## Dataset

The database contains six tables:

| Table | Records |
|---|---:|
| Categories | 94 |
| Products | 4,023 |
| Customers | 40,420 |
| Orders | 159,384 |
| Order Items | 336,559 |
| Inventory Log | 282,352 |

## Key Implementations

- **Database setup:** Created the relational schema and loaded the supplied dataset.
- **Order processing:** Implemented `place_order()` with transaction-safe stock handling.
- **Inventory management:** Implemented `adjust_stock()` to record stock changes.
- **Low-stock reporting:** Created `low_stock_products()` with category hierarchy information.
- **Customer analysis:** Developed an optimised Monday customer-spending report.
- **Data profiling:** Created six reusable SQL scripts to investigate missing values, duplicates, referential integrity, data consistency, category hierarchy issues, and unusual dates or statuses.
- **Validation:** Tested the implementation against a freshly created database and performed concurrent order-placement tests.

## Additional Improvement

A reusable SQL data-profiling toolkit was added under `sql/profiling/`. It allows data-quality checks to be rerun after future data loads rather than relying on one-time investigations.

## Project Structure

```text
Kloud-Kart-PostgreSQL-Assessment/
├── decisions/
├── docs/
│   ├── client_memo.md
│   ├── data_findings.md
│   └── improvement.md
├── reports/
│   └── monday_customer_report.sql
├── sql/
│   ├── profiling/
│   │   ├── 01_null_checks.sql
│   │   ├── 02_duplicate_checks.sql
│   │   ├── 03_referential_integrity_checks.sql
│   │   ├── 04_data_consistency_checks.sql
│   │   ├── 05_category_hierarchy_checks.sql
│   │   └── 06_status_and_date_checks.sql
│   ├── schema.sql
│   ├── load.sql
│   └── solution.sql
└── README.md
```

## Technologies

- PostgreSQL
- SQL
- Docker
- Git and GitHub

## Running the Project

1. Install Docker and ensure it is running.
2. Start a PostgreSQL 18 container.
3. Create the project database.
4. Apply `sql/schema.sql` to create the tables.
5. Run `sql/load.sql` to load the dataset.
6. Run `sql/solution.sql` to install the database functions, sequences, and reporting index.
7. Execute the profiling scripts in `sql/profiling/` to investigate data quality.
8. Run `reports/monday_customer_report.sql` to generate the customer-spending report.

The SQL scripts are intended to be run in the order above where applicable. The profiling scripts are diagnostic and can be executed independently after the data has been loaded.

## Testing and Validation

The implementation was validated against a fresh database. Tests covered database loading, function creation and execution, report generation, transaction rollback, and concurrent order placement to check that stock is not oversold.

## Documentation

Additional project documentation is available in the `docs/` and `decisions/` directories, including data findings, architecture decisions, a client memo, and the additional improvement.

## Note

This is a database engineering assessment project. The profiling scripts identify data-quality issues; they do not automatically modify or repair the source records.