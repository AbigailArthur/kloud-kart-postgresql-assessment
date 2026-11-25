# ADR-001: Inventory Concurrency Control

**Status:** Accepted

## Context
Kloud Kart experiences flash sales where multiple customers may attempt to purchase the last available units of the same product. A normal read-then-update approach can allow concurrent transactions to oversell stock.

## Options considered
- **Application-level locking:** Requires coordination outside the database and can be difficult to maintain consistently.
- **Triggers alone:** Can enforce database rules but do not, by themselves, guarantee safe concurrency across the complete order workflow.
- **Atomic conditional update:** Performs the stock check and deduction in one database statement.

## Decision
Use an atomic conditional `UPDATE` inside the PostgreSQL `place_order()` function:

- Deduct stock only when sufficient quantity is available.
- Return a clear out-of-stock response when the update affects no product row.
- Create the order, order item, and inventory movement within the same transaction.

## Consequences
- Concurrent purchases cannot reduce stock below zero through this function.
- Failed order creation rolls back the stock deduction.
- The database remains responsible for enforcing the critical inventory operation.
- All order placements must use this function to benefit from its protection.

## Validation
The supplied `race_test.py` passed:
- 25/25 rounds of two buyers competing for one unit.
- 400 concurrent buyers competing for 50 units: exactly 50 succeeded.
- Insufficient-stock requests were rejected cleanly.
- Successful purchases generated inventory movement records.