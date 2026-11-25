# Client Memo: Kloud Kart Assessment

**To:** Nana  
**Subject:** Improving Inventory Management and Customer Reporting

## Overview

The assessment reviewed Kloud Kart's inventory records, order information, and customer reports. Several issues were identified that could affect stock availability, record accuracy, and business decisions.

Improvements have also been developed and tested using the company's existing database, without requiring additional infrastructure.

## Key Findings

- **Stock accuracy:** 14 products have negative stock quantities, while 120 stock movement records refer to products that do not exist.
- **Order records:** 692 order items are linked to orders that cannot be found, and 210 orders are linked to customers who cannot be found.
- **Sales figures:** 2,398 orders have recorded totals that do not match the calculated value of their items.
- **Record keeping:** Almost all stock movement records lack explanations of why the changes occurred.
- **Product categories:** Some category records have incorrect relationships, making product classification less reliable.

These problems could lead to inaccurate reports, confusion about available stock, and difficulties tracking business activities.

## Improvements Made

1. **Better stock control:** Introduced a safer purchasing process that prevents customers from buying more units than are available.
2. **Improved stock tracking:** Added a process for recording stock additions and corrections so changes can be traced.
3. **Better low-stock visibility:** Developed a report that identifies products with low stock, including products under nested categories.
4. **Improved customer reporting:** Developed a Monday report showing customer spending, order counts, monthly spending trends, and the top 100 customers.

The customer report completed in less than one second during testing.

## Recommendations

1. Investigate products with negative stock and correct inaccurate inventory records.
2. Review incomplete order and customer records.
3. Investigate differences between recorded order totals and calculated item values.
4. Require staff to provide explanations whenever stock is added, removed, or corrected.
5. Review and correct the product category structure.
6. Ensure staff use the improved purchasing and stock adjustment processes consistently.

## Limitations

The improvements do not automatically correct existing inaccurate records. Some historical stock movements also lack enough information to connect them to specific orders. Existing records will therefore need further review.

## Conclusion

The assessment has provided Kloud Kart with improved stock control, better stock tracking, and faster customer spending reports. Addressing the existing record-keeping issues and consistently following the recommended processes will help the business make more reliable decisions.