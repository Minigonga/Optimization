# Optimization

## B



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