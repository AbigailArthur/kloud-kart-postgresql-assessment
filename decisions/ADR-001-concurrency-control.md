# ADR-001: Inventory Concurrency Control

**Status:** Accepted

## Context

During flash sales, multiple customers may attempt to purchase the remaining units of the same product simultaneously.

A conventional read-then-update workflow can cause a race condition: two transactions may read the same available quantity before either deducts stock, allowing both purchases to proceed and potentially overselling inventory.

The solution must protect stock accuracy under concurrent transactions while keeping order creation and inventory updates consistent.

## Options Considered

1. **Application-level locking:** Rejected because every application instance and purchasing pathway would need to coordinate correctly. A missed lock or additional application could reintroduce the race condition.
2. **Triggers alone:** Rejected as the primary solution because triggers do not automatically make a multi-step purchasing workflow safe. They can also make business logic harder to locate and maintain.
3. **Atomic conditional update:** Selected because PostgreSQL can check available stock and deduct the requested quantity in one operation, avoiding a separate vulnerable read-then-update sequence.

## Decision

Implement inventory purchasing through the PostgreSQL `place_order()` function using an atomic conditional `UPDATE`.

The function:

- Deducts stock only when the product has sufficient available quantity.
- Uses the affected-row result to detect unavailable stock.
- Creates the order, order item, and inventory movement within the same transaction.
- Returns a clear failure response when the requested quantity cannot be fulfilled.

The stock deduction and related order records must succeed or fail together.

## Consequences and Trade-offs

**Benefits:**

- Prevents concurrent purchases through this function from reducing stock below zero.
- Avoids the need for a separate application-level locking mechanism.
- Keeps critical purchasing logic close to the data it protects.
- Ensures failed order creation rolls back the stock deduction.

**Costs and risks:**

- All purchasing pathways must use `place_order()` to receive this protection.
- Direct stock updates or alternative purchasing logic could bypass the safeguard.
- Concurrent requests for the same product may wait for database row locks, so performance must be monitored during high-demand sales.
- The function must be maintained as the purchasing workflow evolves.

If the application bypasses this function, the database protection cannot be assumed to apply to that purchasing operation.
## Cost if the Decision Is Wrong

If this control fails or purchasing operations bypass the function, Kloud Kart could accept orders for stock that is no longer available. This could lead to cancelled orders, customer dissatisfaction, refunds, and additional fulfilment work. During a flash sale, the impact could affect many customers at once.

## Validation

The supplied concurrency race test was executed successfully:

- 25 out of 25 rounds passed with two buyers competing for one unit.
- With 400 concurrent buyers competing for 50 units, exactly 50 purchases succeeded.
- Insufficient-stock requests were rejected.
- Successful purchases generated corresponding inventory movement records.

These tests support the correctness of the implementation under the tested workloads. They do not establish unlimited throughput or production capacity under every flash-sale condition.

## Rejected Alternative and Future Consideration

A trigger-based approach could provide additional protection against certain direct inventory modifications, but it would introduce another layer of business logic to maintain. It may be considered if Kloud Kart later needs to protect stock changes from multiple independent applications or database clients.

For the current assessment, the atomic conditional update provides a simpler and more explicit purchasing control.