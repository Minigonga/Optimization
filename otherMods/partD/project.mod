// Sets
{string} products = ...;
{string} suppliers = ...;

int numPeriods = ...;
range periods = 1..numPeriods;

// BASELINE PARAMETERS
float productUnitArea[products] = ...;
float supplierArea[suppliers] = ...;
int fixedAdminCost = ...;
int coordinationCost = ...;
int warehouseCostPerSqm = ...;
int maxSuppliers = ...;
int maxNumberOfSuppliersPerProduct = ...;
float warehouseArea = ...;

// CHANGED BASELINE PARAMETERS
int productAnnualDemand[products][periods] = ...;

// NEW PARAMETERS
float productDemandGrowthRate[products] = ...;
int supplierSwitchingCost[suppliers] = ...;
int supplierTerminationCost[suppliers] = ...;
int costCapacityExpansion[suppliers][periods] = ...;
float maxCapacityExpansion[suppliers] = ...;
int priceByPeriod[products][periods][suppliers] = ...;
float reliabilityScore[suppliers] = ...;
float qualityScore[suppliers] = ...;
float sustainabilityScore[suppliers] = ...;
float weightCost = ...;
float weightReliability = ...;
float weightQuality = ...;
float weightSustainability = ...;


// Decision variables
dvar int+ quantityOfProductFromSupplier[products][suppliers][periods];
dvar boolean ProductDeliverFromSupplier[products][suppliers][periods];
dvar boolean UsedSuppliers[suppliers][periods];
dvar float+ quantityOfAreaPerSupplier[suppliers][periods];

// Transition & Expansion Variables
dvar boolean CapacityExpanded[suppliers][periods];
dvar float+ expandedCapacity[suppliers][periods];
dvar boolean SupplierInitiated[suppliers][periods];
dvar boolean SupplierSwitchedOn[suppliers][periods];
dvar boolean SupplierTerminated[suppliers][periods];

// Multi-objective components 
dvar float totalCost;
dvar float totalReliability;
dvar float totalQuality;
dvar float totalSustainability;

// Objective Function
minimize
    weightCost * totalCost
    - weightReliability * totalReliability * 100
    - weightQuality * totalQuality * 100
    - weightSustainability * totalSustainability * 100;

// Constraints 
subject to {

    // Cost calculation constraint
    ctTotalCost:
    totalCost ==
        sum(t in periods) (
            sum(j in suppliers) fixedAdminCost * UsedSuppliers[j][t]
            + sum(i in products, j in suppliers) coordinationCost * ProductDeliverFromSupplier[i][j][t]
            + sum(j in suppliers) warehouseCostPerSqm * quantityOfAreaPerSupplier[j][t]
            + sum(i in products, j in suppliers) priceByPeriod[i][t][j] * quantityOfProductFromSupplier[i][j][t]
        )
        + sum(t in periods : t > 1, j in suppliers) supplierSwitchingCost[j] * SupplierSwitchedOn[j][t]
        + sum(t in periods : t > 1, j in suppliers) supplierTerminationCost[j] * SupplierTerminated[j][t]
        + sum(t in periods, j in suppliers) costCapacityExpansion[j][t] * CapacityExpanded[j][t];

    // Multi-objective metrics
    ctTotalReliability:
    totalReliability == sum(t in periods, j in suppliers) reliabilityScore[j] * UsedSuppliers[j][t];

    ctTotalQuality:
    totalQuality == sum(t in periods, j in suppliers) qualityScore[j] * UsedSuppliers[j][t];

    ctTotalSustainability:
    totalSustainability == sum(t in periods, j in suppliers) sustainabilityScore[j] * UsedSuppliers[j][t];

    forall(t in periods) {
        
        forall(i in products)
            ctDemand:
            sum(j in suppliers) quantityOfProductFromSupplier[i][j][t] == productAnnualDemand[i][t];

        forall(i in products, j in suppliers)
            ctLinkXY:
            quantityOfProductFromSupplier[i][j][t] <= productAnnualDemand[i][t] * ProductDeliverFromSupplier[i][j][t];

        forall(i in products)
            ctMaxSuppliersPerProduct:
            sum(j in suppliers) ProductDeliverFromSupplier[i][j][t] <= maxNumberOfSuppliersPerProduct;

        ctMaxSuppliers:
        sum(j in suppliers) UsedSuppliers[j][t] <= maxSuppliers;

        forall(i in products, j in suppliers)
            ctLinkYZ:
            ProductDeliverFromSupplier[i][j][t] <= UsedSuppliers[j][t];

        forall(j in suppliers)
            ctMinReservedArea:
            quantityOfAreaPerSupplier[j][t] >= 0.05 * sum(i in products) productUnitArea[i] * quantityOfProductFromSupplier[i][j][t];

        // since CapacityExpanded[j][1] == 0, it acts as a normal capacity constraint in period 1 automatically
        forall(j in suppliers)
            ctSupplierCapacity:
            sum(i in products) productUnitArea[i] * quantityOfProductFromSupplier[i][j][t] <= supplierArea[j] + expandedCapacity[j][t];

        forall(j in suppliers)
            ctMaxCapacityExpansion:
            expandedCapacity[j][t] <= maxCapacityExpansion[j] * CapacityExpanded[j][t];

        ctMaxWarehouseArea:
        sum(j in suppliers) quantityOfAreaPerSupplier[j][t] <= warehouseArea;

        ctGammaSwitch:
        quantityOfProductFromSupplier["Access Switch"]["Supplier Gamma"][t]
            <= 0.25 * productAnnualDemand["Access Switch"][t]
            + productAnnualDemand["Access Switch"][t] * (1 - ProductDeliverFromSupplier["UPS 1 kVA"]["Supplier Gamma"][t]);

        ctGammaMiniPC:
        quantityOfProductFromSupplier["Mini PC"]["Supplier Gamma"][t]
            <= 0.10 * productAnnualDemand["Mini PC"][t]
            + productAnnualDemand["Mini PC"][t] * (1 - ProductDeliverFromSupplier["UPS 1 kVA"]["Supplier Gamma"][t]);
    }

    // TRANSITION LOGIC
    // FOR PERIOD 1: INITIALIZATION
    forall(j in suppliers) {
        ctSupplierInitiated:
        SupplierInitiated[j][1] == UsedSuppliers[j][1];
        
        ctNoSwitchP1:
        SupplierSwitchedOn[j][1] == 0;
        
        ctNoTerminateP1:
        SupplierTerminated[j][1] == 0;
        
        ctNoCapacityExpansionP1:
        CapacityExpanded[j][1] == 0;
    }

    // FOR PERIODS > 1
    forall(t in periods : t > 1, j in suppliers) {
        ctSwitchOn:
        SupplierSwitchedOn[j][t] >= UsedSuppliers[j][t] - UsedSuppliers[j][t-1];
        
        ctTerminate:
        SupplierTerminated[j][t] >= UsedSuppliers[j][t-1] - UsedSuppliers[j][t];
        
        ctNoSimultaneousTransition:
        SupplierSwitchedOn[j][t] + SupplierTerminated[j][t] <= 1;
    }
}

// ======================================================
// RESULTS
// ======================================================

execute {
    writeln("\n========== PART D: RESULTS ==========\n");

    writeln("--- MULTI-OBJECTIVE OPTIMIZATION WEIGHTS ---");
    writeln("Cost Weight                = ", weightCost);
    writeln("Reliability Weight         = ", weightReliability);
    writeln("Quality Weight             = ", weightQuality);
    writeln("Sustainability Weight      = ", weightSustainability);

    writeln("\n--- OBJECTIVE VALUE ---");
    writeln("Multi-Objective Score = ", cplex.getObjValue());
    
    var totalActiveSuppliers = 0;
    for(var t in periods) {
        for(var j in suppliers) {
            totalActiveSuppliers += UsedSuppliers[j][t];
        }
    }
    
    var calcAvgRel = totalActiveSuppliers > 0 ? (totalReliability / totalActiveSuppliers) : 0;
    var calcAvgQual = totalActiveSuppliers > 0 ? (totalQuality / totalActiveSuppliers) : 0;
    var calcAvgSust = totalActiveSuppliers > 0 ? (totalSustainability / totalActiveSuppliers) : 0;

    writeln("Total Cost            = ", totalCost);
    writeln("Avg Reliability Score = ", calcAvgRel);
    writeln("Avg Quality Score     = ", calcAvgQual);
    writeln("Avg Sustainability    = ", calcAvgSust);

    // --------------------------------------------------
    // Product capacity requirements
    // --------------------------------------------------
    writeln("\n--- PRODUCT CAPACITY REQUIREMENTS (By Period) ---");
    for(var t in periods) {
        writeln("\nPeriod ", t, ":");
        for(var i in products) {
            var requiredArea = productUnitArea[i] * productAnnualDemand[i][t];
            writeln("  ", i, " | Required Area = ", requiredArea);
        }
    }

    // --------------------------------------------------
    // Warehouse utilization
    // --------------------------------------------------
    writeln("\n--- WAREHOUSE CAPACITY UTILIZATION (By Period) ---");
    for(var t in periods) {
        var totalReservedArea = 0;
        for(var j in suppliers) {
            totalReservedArea += quantityOfAreaPerSupplier[j][t];
        }
        writeln("\nPeriod ", t, ":");
        writeln("  Warehouse Limit       = ", warehouseArea);
        writeln("  Reserved Area         = ", totalReservedArea);
        writeln("  Warehouse Slack       = ", warehouseArea - totalReservedArea);
        writeln("  Warehouse Utilization = ", (totalReservedArea / warehouseArea) * 100, "%");
    }

    // --------------------------------------------------
    // Supplier capacity utilization
    // --------------------------------------------------
    writeln("\n--- SUPPLIER CAPACITY UTILIZATION (By Period) ---");
    for(var t in periods) {
        writeln("\nPeriod ", t, ":");
        for(var j in suppliers) {
            var usedArea = 0;
            for(var i in products) {
                usedArea += productUnitArea[i] * quantityOfProductFromSupplier[i][j][t];
            }
            var currentSupplierCapacity = supplierArea[j] + expandedCapacity[j][t];
            
            writeln("  ", j, " | Used = ", usedArea, 
                    " / Capacity = ", currentSupplierCapacity, 
                    " | Slack = ", currentSupplierCapacity - usedArea, 
                    " | Utilization = ", (usedArea / currentSupplierCapacity) * 100, "%");
        }
    }

    // --------------------------------------------------
    // Product price spread analysis
    // --------------------------------------------------
    writeln("\n--- PRODUCT PRICE SPREAD ANALYSIS (By Period) ---");
    for(var t in periods) {
        writeln("\nPeriod ", t, ":");
        for(var i in products) {
            var minPrice = 1e9;
            var maxPrice = 0;
            var bestSupplier = "";

            for(var j in suppliers) {
                if(priceByPeriod[i][t][j] < minPrice) {
                    minPrice = priceByPeriod[i][t][j];
                    bestSupplier = j;
                }
                if(priceByPeriod[i][t][j] > maxPrice) {
                    maxPrice = priceByPeriod[i][t][j];
                }
            }
            writeln("  ", i, " | Cheapest Supplier = ", bestSupplier, 
                    " | Min Price = ", minPrice, 
                    " | Max Price = ", maxPrice, 
                    " | Spread = ", maxPrice - minPrice);
        }
    }

    // --------------------------------------------------
    // Supplier concentration
    // --------------------------------------------------
    writeln("\n--- SUPPLIER CONCENTRATION (By Period) ---");
    for(var t in periods) {
        writeln("\nPeriod ", t, ":");
        for(var j in suppliers) {
            var totalUnits = 0;
            for(var i in products) {
                totalUnits += quantityOfProductFromSupplier[i][j][t];
            }
            writeln("  ", j, " | Total Units Assigned = ", Math.round(totalUnits));
        }
    }

    writeln("\n--- DETAILED COST BREAKDOWN BY PERIOD ---");
    for(var t in periods) {
        var adminCost = 0;
        var coordCost = 0;
        var warehouseCost = 0;
        var purchasingCost = 0;
        var expansionCost = 0;

        for(var j in suppliers) {
            adminCost += fixedAdminCost * UsedSuppliers[j][t];
            warehouseCost += warehouseCostPerSqm * quantityOfAreaPerSupplier[j][t];
            expansionCost += costCapacityExpansion[j][t] * CapacityExpanded[j][t];
        }

        for(var i in products) {
            for(var j in suppliers) {
                coordCost += coordinationCost * ProductDeliverFromSupplier[i][j][t];
                purchasingCost += priceByPeriod[i][t][j] * quantityOfProductFromSupplier[i][j][t];
            }
        }

        writeln("\nPeriod ", t, ":");
        writeln("  Administrative Cost  = ", adminCost);
        writeln("  Coordination Cost    = ", coordCost);
        writeln("  Warehouse Cost       = ", warehouseCost);
        writeln("  Purchasing Cost      = ", purchasingCost);
        writeln("  Capacity Expansion   = ", expansionCost);
        writeln("  Period Total         = ", adminCost + coordCost + warehouseCost + purchasingCost + expansionCost);
    }

    writeln("\n--- VARIABLE SWITCHING COSTS (by supplier) ---");
    for(var t in periods) {
        if(t > 1) {
            for(var j in suppliers) {
                if(SupplierSwitchedOn[j][t] > 0.5) {
                    writeln("Period ", t, ": ", j, " activated (cost: €", supplierSwitchingCost[j], ")");
                }
                if(SupplierTerminated[j][t] > 0.5) {
                    writeln("Period ", t, ": ", j, " terminated (cost: €", supplierTerminationCost[j], ")");
                }
            }
        }
    }

    writeln("\n--- SUPPLIER CAPACITY EXPANSION DECISIONS ---");
    for(var t in periods) {
        for(var j in suppliers) {
            if(CapacityExpanded[j][t] > 0.5) {
                var expansionAmount = expandedCapacity[j][t];
                var newCapacity = supplierArea[j] + expansionAmount;
                writeln("Period ", t, ": ", j, " expands capacity by ", expansionAmount, 
                    " m² (from ", supplierArea[j], " to ", newCapacity, ") - Cost: €", 
                    costCapacityExpansion[j][t]);
            }
        }
    }

    writeln("\n--- SUMMARY AND RELATIONSHIP PRESSURE ---");
    for(var t in periods) {
        var numSuppliers = 0;
        var numRelationships = 0;
        var totalArea = 0;

        for(var j in suppliers) {
            numSuppliers += UsedSuppliers[j][t];
            totalArea += quantityOfAreaPerSupplier[j][t];
        }

        for(var i in products)
            for(var j in suppliers)
                numRelationships += ProductDeliverFromSupplier[i][j][t];

        writeln("\nPeriod ", t, ":");
        writeln("  Selected Suppliers      = ", numSuppliers);
        writeln("  Active Relationships    = ", numRelationships);
        writeln("  Max Possible Relations  = ", products.size * maxNumberOfSuppliersPerProduct);
        writeln("  Relation Saturation     = ", (numRelationships / (products.size * maxNumberOfSuppliersPerProduct)) * 100, "%");
        writeln("  Reserved Warehouse Area = ", totalArea);
    }

    writeln("\n--- SUPPLIER PORTFOLIO QUALITY METRICS ---");
    for(var j in suppliers) {
        var isUsed = false;
        for(var t in periods) {
            if(UsedSuppliers[j][t] > 0.5) {
                isUsed = true;
                break;
            }
        }
        if(isUsed) {
            writeln("\n", j, ":");
            writeln("  Reliability Score  = ", reliabilityScore[j]);
            writeln("  Quality Score      = ", qualityScore[j]);
            writeln("  Sustainability     = ", sustainabilityScore[j]);
        }
    }

    writeln("\n--- SUPPLIER PORTFOLIO EVOLUTION ---");
    for(var j in suppliers) {
        writeln("\n", j, ":");
        for(var t in periods) {
            if(UsedSuppliers[j][t] > 0.5) {
                writeln("  Period ", t, ": ACTIVE", 
                    (SupplierSwitchedOn[j][t] > 0.5 ? " (newly activated)" : ""),
                    (SupplierTerminated[j][t] > 0.5 ? " (terminated)" : ""));
            } else {
                writeln("  Period ", t, ": Not used");
            }
        }
    }

    writeln("\n--- PRODUCT ALLOCATIONS BY PERIOD ---");
    for(var t in periods) {
        writeln("\nPeriod ", t, ":");
        for(var i in products) {
            var totalQty = 0;
            for(var j in suppliers) {
                totalQty += quantityOfProductFromSupplier[i][j][t];
            }
            
            writeln("  ", i, " (Total: ", Math.round(totalQty), " units)");
            for(var j in suppliers) {
                if(quantityOfProductFromSupplier[i][j][t] > 0.001) {
                    var unitPrice = priceByPeriod[i][t][j];
                    var qty = Math.round(quantityOfProductFromSupplier[i][j][t]);
                    var cost = unitPrice * qty;
                    writeln("    ", j, " -> ", qty, " units @ €", unitPrice, "/unit (€", cost, ")");
                }
            }
        }
    }
}