# ADR-002: Recursive Category Reporting

**Status:** Accepted

## Context
Kloud Kart's product categories form a parent-child hierarchy. The data contains an orphan parent reference and a circular relationship, so fixed-depth queries could produce incomplete results or enter infinite recursion.

## Options considered
- **Fixed-depth joins:** Simple but fail when new hierarchy levels are added.
- **Recursive CTE:** Supports arbitrary depth and can track visited categories to detect cycles.

## Decision
Use a PostgreSQL recursive CTE in `low_stock_products()`.

The function:
- Traverses categories from root nodes without hardcoded depth.
- Tracks visited category IDs to prevent infinite recursion.
- Identifies category cycles and missing parent references.
- Includes products without categories as `Uncategorized`.
- Returns category paths, depth, stock quantity, and integrity flags.

## Consequences
- New category levels are supported without changing the query.
- Category problems remain visible instead of being silently ignored.
- Products with missing category assignments can still appear in low-stock reporting.
- Invalid source relationships still require investigation and correction.

## Validation
- The function identified 1,685 low-stock products.
- It identified 12 uncategorized products and three products associated with the detected category cycle.
- A temporary product test confirmed that missing-parent categories are flagged correctly.