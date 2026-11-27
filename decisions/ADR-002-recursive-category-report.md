# ADR-002: Recursive Category Reporting

**Status:** Accepted

## Context

Kloud Kart's product categories form a parent-child hierarchy. The supplied data contains a missing-parent reference and a circular relationship.

A reporting query must support nested categories of varying depth without omitting products or entering infinite recursion when invalid relationships exist.

## Options Considered

1. **Fixed-depth joins:** Rejected because they require a predefined number of hierarchy levels. Every additional level would require query changes, increasing maintenance effort and creating a risk of incomplete reporting.
2. **Recursive Common Table Expression (CTE):** Selected because PostgreSQL can traverse parent-child relationships to arbitrary depth while maintaining a record of visited category IDs to detect cycles.

## Decision

Use a PostgreSQL recursive CTE in `low_stock_products()`.

The function:

- Starts from each product's assigned category and follows parent links upward without hardcoding hierarchy depth.
- Tracks visited category IDs to prevent infinite recursion.
- Identifies category cycles and missing-parent relationships.
- Includes products without category assignments as `Uncategorized`.
- Returns category paths, hierarchy depth, stock quantities, and relevant integrity flags.

## Consequences and Trade-offs

**Benefits:**

- Supports additional category levels without requiring fixed-depth query changes.
- Makes hierarchy defects visible instead of silently ignoring them.
- Allows uncategorized products to remain visible in low-stock reporting.
- Keeps hierarchy traversal and low-stock filtering within PostgreSQL.

**Costs and risks:**

- Recursive queries require careful cycle detection to avoid repeated traversal.
- Large or deeply nested hierarchies may increase query cost.
- The function reports structural problems but does not automatically repair incorrect category relationships.
- Invalid parent references and cycles still require business review.

## Cost if the Decision Is Wrong

If the hierarchy traversal is incorrect, Kloud Kart could receive incomplete or misleading category paths in low-stock reports. Products may be associated with the wrong category, and circular relationships could prevent reports from completing correctly. This could lead to poor stock-management and replenishment decisions.
## Validation

The function returned 1,685 low-stock products for the tested threshold.

Within that result:

- 12 products had no category assignment.
- Three products were associated with the detected category cycle.
- A temporary product test confirmed that missing-parent categories are flagged correctly.

The separate profiling assessment identified 37 uncategorized products across the full product catalogue. The 12 returned by the function are therefore the low-stock subset, not the total number of uncategorized products.

The category profiling checks also identified 94 total categories, 91 reachable from roots, and three unreachable categories.

## Rejected Alternative and Future Consideration

Fixed-depth joins would be simpler for a permanently shallow hierarchy, but they would become increasingly difficult to maintain as Kloud Kart adds categories and subcategories.

If the hierarchy grows substantially, query performance should be measured using realistic category and product volumes. Additional indexing or a different hierarchy representation should only be considered if measurements demonstrate a need.
