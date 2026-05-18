# Optimization

## B

### Supplier Epsilon Capacity

This an important choice the problem because all the capacity from supplier epsilon is being used as it can be seen in the parameter check
```
Supplier Epsilon | Used = 23.48 / Capacity = 23.5 | Slack = 0.02 | Utilization = 99.914893617%
```
This indicates that it is a highly restrictive parameter.

Since it is being completely used we can assume that it is the best option doing that lowering the capacity it will affect negatively the objective function (it will have a bigger cost) and if the capacity increases it will affect it positively. There will be a value where the epsilon supplier will stop being used because with the supplier and other 3 it won't be enough to get all the products needed so it wil be necessary to use the supplier that in the normal scenario is not used.

#### Scenario 1 (capacity slightly lower)

The epsilon capacity is reduced to 22m^2.

In this case the cost of everything will be 205264 that is higher then what we had previously as we predicted before. The area lost is redistributed by the rest of the suppliers and the capacity of epsilon is still being used to its fullest.

#### Scenario 2 (capacity lower that the supplier stops being used)

The epsilon capacity is reduced to 16m^2.

In this case the cost of everything will be 206684 that is a big difference to the small difference we had before. That occurs because the supplier stops being used as we predicted and we start using a supplier that isn't as worth as the epsilon.

#### Scenario 3 (capacity slightly higher)

The epsilon capacity is increased to 26m^2.

In this case the cost of everything will be 205164 that is what we predicted. Some of the capacity from other suppliers to use the full capacity of epsilon even tho it increased.

#### Scenario 4 (capacity higher enough to stop epsilon of being used fully)

The epsilon capacity is increased to 32m^2.

In this case the cost of everything will be 204388. The thing that we didn't predict was that the capacity wouldn't be used fully, probably because epsilon buys the stock of every product and the other products that will be bought from other suppliers won't be good to buy from epsilon. With this in mind probably with more capacity on epsilon that fully covers the capacity of another product it will use that capacity.

## C

The hard constraint the we made softer was the: 
```
    forall(j in suppliers)
        ctSupplierCapacity:
        sum(i in products) productUnitArea[i] * quantityOfProductFromSupplier[i][j] <= supplierArea[j];
```

This constraint represents a real limit that is the limited capacity of area assigned to a supplier. The capacity could be bigger if we paid more money to the supplier, for example we could have an agreement of a certain amount for m^2 more than the capacity agreed.

For that we replaced the constraint for:
```    
    forall(j in suppliers)
        ctSupplierCapacity:
        sum(i in products) productUnitArea[i] * quantityOfProductFromSupplier[i][j] <= supplierArea[j] + supplierOverflow[j];
```

SupplierOverflow is a new decision varialbe that is a list of floats that have the capacity passed from the capacity agreed. We also added a parameter (supplierOverflowPenalty) that can be adjusted that will be the penalty.

```
float supplierOverflowPenalty = ...;
dvar float supplierOverflow[suppliers];
```

For the penalization to be applied in the objective function we also need to change the objective function:

```
 minimize
    sum(j in suppliers) fixedAdminCost * UsedSuppliers[j]
    + sum(i in products, j in suppliers) coordinationCost * ProductDeliverFromSupplier[i][j]
    + sum(j in suppliers) warehouseCostPerSqm * quantityOfAreaPerSupplier[j]
    + sum(i in products, j in suppliers) productPricePerSupplier[i][j] * quantityOfProductFromSupplier[i][j]
 	+ sum(j in suppliers) supplierOverflowPenalty * supplierOverflow[j];
```

### Experiments



## AI

- Used to get a print that made the results easy to read
- Parameters check to know the best to change