# Kloud Kart PostgreSQL Assessment

A PostgreSQL database engineering project focused on building, validating, and improving the data operations of a fictional e-commerce business, Kloud Kart.

## Project Overview

This project uses an e-commerce dataset containing customers, products, categories, orders, order items, and inventory records.

The objectives are to establish a reliable PostgreSQL database, investigate data-quality issues, implement essential database operations, and support customer-spending analysis.

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
- **Order processing:** Implemented `place_order()` with atomic stock updates to prevent overselling during concurrent transactions.
- **Inventory management:** Implemented `adjust_stock()` to update stock quantities and record inventory movements.
- **Low-stock reporting:** Created `low_stock_products()` using recursive category traversal to provide category hierarchy information.
- **Customer analysis:** Developed a Monday customer-spending report showing monthly spending, order counts, cumulative spending, and customer rankings.
- **Data profiling:** Created six reusable SQL scripts covering missing values, duplicates, referential integrity, data consistency, category hierarchy issues, and unusual dates or statuses.
- **Validation:** Executed the solution against a fresh database and tested concurrent order placement under stock contention.

## Additional Improvement

A reusable SQL data-profiling toolkit was added under `sql/profiling/`. It allows data-quality checks to be rerun after future data loads rather than relying on one-time investigations.

The toolkit identifies potential data-quality issues. It does not automatically correct records or schedule recurring checks.

## Project Structure

```text
Kloud-Kart-PostgreSQL-Assessment/
|-- decisions/
|   |-- ADR-001-concurrency-control.md
|   |-- ADR-002-recursive-category-report.md
|   `-- ADR-003-report-performance.md
|-- data/
|   |-- categories.csv
|   |-- customers.csv
|   |-- inventory_log.csv
|   |-- order_items.csv
|   |-- orders.csv
|   `-- products.csv
|-- docs/
|   |-- client_memo.md
|   |-- data_findings.md
|   `-- improvement.md
|-- reports/
|   `-- monday_customer_report.sql
|-- sql/
|   |-- profiling/
|   |   |-- 01_null_checks.sql
|   |   |-- 02_duplicate_checks.sql
|   |   |-- 03_referential_integrity_checks.sql
|   |   |-- 04_data_consistency_checks.sql
|   |   |-- 05_category_hierarchy_checks.sql
|   |   `-- 06_status_and_date_checks.sql
|   |-- load.sql
|   |-- schema.sql
|   `-- solution.sql
|-- tests/
|   `-- race_test.py
`-- README.md
```

## Technologies

- PostgreSQL 18
- SQL
- Python 3
- Docker
- Git and GitHub
- `psycopg2-binary`

## Running the Project

### Prerequisites

- Docker Desktop
- PostgreSQL 18 Docker image
- Python 3
- Python package: `psycopg2-binary`

Run the commands from the project root directory.

### Database Setup

Create a fresh or disposable PostgreSQL database before running the setup scripts.

**Important:** `sql/schema.sql` drops and recreates the project tables. Do not run it against a database containing data you need to preserve.

The setup scripts must be executed in this order:

1. `sql/schema.sql` â€” creates the database tables.
2. `sql/load.sql` â€” loads the supplied CSV data.
3. `sql/solution.sql` â€” installs the database functions and ID-generation defaults.

Before running these commands, make sure Docker Desktop is running and the `kloud-kart-postgres` container is up.

Check the container status:

```powershell
docker ps
```

If the container exists but is stopped, start it:

```powershell
docker start kloud-kart-postgres
```

Make sure the target database (`kloudkart_fresh` in this example) already exists. The commands below do not create the database.

#### Using Docker from Windows PowerShell

The following example uses the container `kloud-kart-postgres`, database `kloudkart_fresh`, and PostgreSQL user `klouduser`. Change these values if your environment uses different names.

First, copy the setup files and dataset into the running container:

```powershell
$container = "kloud-kart-postgres"

docker exec $container mkdir -p /workspace

docker cp .\sql\schema.sql "${container}:/workspace/schema.sql"
docker cp .\sql\load.sql "${container}:/workspace/load.sql"
docker cp .\sql\solution.sql "${container}:/workspace/solution.sql"
docker cp .\data "${container}:/workspace/data"
```

Then execute the scripts in order:

```powershell
docker exec -w /workspace $container psql -U klouduser -d kloudkart_fresh -v ON_ERROR_STOP=1 -f schema.sql

docker exec -w /workspace $container psql -U klouduser -d kloudkart_fresh -v ON_ERROR_STOP=1 -f load.sql

docker exec -w /workspace $container psql -U klouduser -d kloudkart_fresh -v ON_ERROR_STOP=1 -f solution.sql
```

The working directory is set to `/workspace` so that relative CSV paths used by the loading script resolve correctly inside the container.

### Data Profiling

After loading the data, execute the SQL scripts in `sql/profiling/` independently.

The scripts investigate:

- Missing and null values.
- Potential duplicate records.
- Referential integrity issues.
- Data consistency problems.
- Category hierarchy problems.
- Unusual statuses and dates.

These checks can be rerun after subsequent data loads.

### Customer-Spending Report

Run `reports/monday_customer_report.sql` to generate the customer-spending report.

For the Docker setup above, first copy the report into the container:

```powershell
docker cp .\reports\monday_customer_report.sql "${container}:/workspace/monday_customer_report.sql"
```

Then execute it:

```powershell
docker exec -w /workspace $container psql -U klouduser -d kloudkart_fresh -v ON_ERROR_STOP=1 -f monday_customer_report.sql
```

### Concurrent Order Testing

Install the Python dependency:

```powershell
python -m pip install psycopg2-binary
```

Configure the `DATABASE_URL` environment variable with a connection string pointing to the database being tested.

For example, in PowerShell:

```powershell
$env:DATABASE_URL = "postgresql://klouduser:YOUR_PASSWORD@localhost:5432/kloudkart_fresh"
```

Replace `YOUR_PASSWORD` with the PostgreSQL password.

Run the concurrency test from the project root:

```powershell
python tests/race_test.py
```

The test validates concurrent order placement under limited stock, including:

- Two buyers competing for the final unit.
- A flash sale with more buyers than available units.
- Requests exceeding available stock.
- Inventory audit records following successful sales.

## Performance Evaluation

The customer report was benchmarked before and after testing a partial index and a larger `work_mem` setting.

The tested index and memory adjustment did not improve execution time, so neither was retained as a performance optimization in the final solution.

The benchmark measurements and findings are documented in `docs/data_findings.md` and `decisions/ADR-003-report-performance.md`.

The measurements represent the tested database environment and should not be interpreted as guaranteed production performance.
