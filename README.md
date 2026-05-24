# Optimization

## B

### Supplier Epsilon capacity

The capacity of supplier Epsilon is an important parameter because the parameter check shows it is nearly fully used:
```
Supplier Epsilon | Used = 23.48 / Capacity = 23.5 | Slack = 0.02 | Utilization = 99.914893617%
```
This indicates Epsilon is a binding (restrictive) capacity in the baseline instance.

Since Epsilon is fully utilized in the baseline, reducing its capacity will typically increase total cost (more expensive substitutions), while increasing its capacity tends to reduce cost until another constraint becomes binding. There will be a threshold where Epsilon is no longer selected because the combination of 4 suppliers with Epsilon will not be able to cover all the capacity for the demanded products.

#### Scenario 1 — Epsilon capacity = 22 m^2 (slightly lower)

Total cost: 205264 (higher than baseline). The capacity shortfall is redistributed across the other suppliers; Epsilon remains fully used.

#### Scenario 2 — Epsilon capacity = 16 m^2 (reduced enough to drop Epsilon)

Total cost: 206684 (noticeably higher). Epsilon is no longer used and a less cost-effective supplier is used instead, increasing total cost.

#### Scenario 3 — Epsilon capacity = 26 m^2 (slightly higher)

Total cost: 205164. Other suppliers still use some capacity even though Epsilon increased; the marginal benefit is small.

#### Scenario 4 — Epsilon capacity = 32 m^2 (larger increase)

Total cost: 204388. Epsilon is no longer fully used — other products are not always optimal to source from Epsilon even when it has spare capacity.

#### Scenario 5 — Epsilon capacity = 40 m^2 (unrealistic large increase)

Total cost: 203828. This unrealistic scenario, because the capacity is way higher than what we had, shows that, with large extra capacity, many products shift to Epsilon (e.g., `Access Switch` is fully sourced from Epsilon), reducing total cost further.

### Warehouse area

There is no feasible solution when the total warehouse area is below 4.26.

### Max suppliers (changing the limit)

If the limit on selected suppliers is removed, the optimal solution could improve if using all five suppliers is cheaper than restricting to four. If not, the solution remains unchanged. If the limit is tightened, feasibility can be lost because supplier capacities may be insufficient.

#### Scenario 1 — Allow all suppliers

Removing the `maxSuppliers` limit did not change the optimal solution in the baseline: it is still not beneficial to include Supplier Delta because its fixed/relationship costs and prices keep it out of the optimal mix.

#### Scenario 2 — Allow all suppliers and lower fixed admin cost

Example: `fixedAdminCost = 350` and `coordinationCost = 320` (unrealistic). In this case all suppliers become used; Supplier Delta supplies the Wi‑Fi Access Point.

#### Scenario 3 — `maxSuppliers = 3`

No feasible solution under this restriction: no combination of three suppliers has sufficient capacity to satisfy all demand.

### Supplier–product relationship cost

The `coordinationCost` (supplier–product relation) influences whether it is worth opening additional relationships. In the baseline, some products are split across two suppliers because of capacity limits rather than coordination cost.

#### Scenario 1 — `coordinationCost = 350`

The optimal solution is unchanged: existing relationships already reflect best-price sourcing given capacities.

#### Scenario 2 — `coordinationCost = 1200`

The optimal solution is still unchanged because the model is already at the minimum number of relationships required by capacity.

#### Scenario 3 — `Epsilon capacity = 32`

With more space in Epsilon (same as Epsilon capacity scenario 4), IP Camera demand is fully sourced from Epsilon and one supplier–product relationship is avoided.

### Enterprise Router price

The Enterprise Router has a high impact on total purchasing cost because of its demand and price spread. If the price ordering stays the same (Beta remains relatively cheaper than others), allocations remain unchanged. If Delta becomes cheaper than Beta by a sufficient margin, allocations may switch, but the change must compensate for any other products currently sourced from Beta (for example, IP Camera).

Even when the supplier for Enterprise Router changes, the model typically continues to source another product from that supplier due to capacity and the four-supplier limit. Enterprise Router total area is 14.4 m^2, so its direct effect on supplier capacity is limited.

#### Scenario 1 — All Enterprise Router prices reduced by 5 units: `[465, 450, 457, 475, 463]`

Solution: same allocation as baseline, with a lower total cost.

#### Scenario 2 — Delta slightly cheaper than Beta for Enterprise Router: `[470, 455, 462, 454, 468]`

Solution: allocations unchanged because Beta remains cost-effective when considering its other products (e.g., IP Camera).

#### Scenario 3 — Delta reasonably cheaper than Beta for Enterprise Router: `[470, 455, 462, 450, 468]`

Solution: some products previously bought from Beta shift to Delta, since the Enterprise Router price advantage compensates the IP Camera sourcing difference.

#### Scenario 4 — Beta price increases substantially: `[470, 475, 462, 450, 468]`

Solution: allocations change — Gamma may supply the Enterprise Router, Beta shifts to supplying UPS 1 kVA, IP Cameras move to Epsilon, and the Mini PC may be split between Gamma and Epsilon. Capacity interactions limit perfect consolidation.

## C

We softened the supplier capacity constraint:
```
    forall(j in suppliers)
        ctSupplierCapacity:
        sum(i in products) productUnitArea[i] * quantityOfProductFromSupplier[i][j] <= supplierArea[j];
```

This constraint represents each supplier's agreed capacity. In practice, a supplier could agree to provide additional area for a penalty.

We replaced the hard constraint with a softened version:
```    
    forall(j in suppliers)
        ctSupplierCapacity:
        sum(i in products) productUnitArea[i] * quantityOfProductFromSupplier[i][j] <= supplierArea[j] + supplierOverflow[j];
```

`supplierOverflow` is a decision variable (a vector of floats) that allows exceeding agreed capacity. We introduced a penalty parameter `supplierOverflowPenalty` to charge for overflow:

```
float supplierOverflowPenalty = ...;
dvar float supplierOverflow[suppliers];
```

The objective is adjusted to penalize overflow:
```
 minimize
    sum(j in suppliers) fixedAdminCost * UsedSuppliers[j]
    + sum(i in products, j in suppliers) coordinationCost * ProductDeliverFromSupplier[i][j]
    + sum(j in suppliers) warehouseCostPerSqm * quantityOfAreaPerSupplier[j]
    + sum(i in products, j in suppliers) productPricePerSupplier[i][j] * quantityOfProductFromSupplier[i][j]
 	+ sum(j in suppliers) supplierOverflowPenalty * supplierOverflow[j];
```

### Experiments
! All lists follow the supplier order given in the PDF.
#### All Penalty 50

Result: [0,4.2,0,0,13.5]
This is a low penalty, so taking it is worthwhile. Using the extra area avoids the need to create new supplier-product relationships and allows many products to be bought from the cheapest supplier.

#### All Penalty 157

Result: [0,0,0,0,0]
This is the lowest penalty at which using the overflow is no longer worthwhile.

#### Different Penalty [80, 100, 90, 90, 100]

Result: [0,4.2,0,0,2.7]
This is a typical case where penalties vary across suppliers and none are extreme. A per-supplier penalty vector makes sense because agreements often differ by supplier.

#### Different Penalty [999999, 999999, 999999, 999999, 100]

Result: [0,0,0,0,5.5]
This forces overflow to be used only for Supplier Epsilon (only Epsilon has a reasonable penalty).

#### Different Penalty [100, 160, 100, 100, 160]

Result: [0,0,0,3.1,2.7]
Here, Beta's overflow penalty is high enough that it is no longer used; Delta and Epsilon are used instead, with Epsilon still supplying some overflow because it remains cost-effective.

## AI

- Used to get a print that made the results easy to read
- Parameters check to know the best to change on part B