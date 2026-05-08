/*********************************************
 * OPL 22.1.2.0 Model
 * Author: minig
 * Creation Date: 08/05/2026 at 03:12:58
 *********************************************/

// Sets
 {string} products = ...;
 {string} suppliers = ...;
 
 
 // Parameters
 int productPricePerSupplier[products][suppliers] = ...;
 int productAnnualDemand[products] = ...;
 float productUnitArea[products] = ...;
 float supplierArea[suppliers] = ...;
 int fixedAdminCost = ...;
 int coordinationCost = ...;
 int warehouseCostPerSqm = ...;
 
 
 // Decision variables
 dvar int+ quantityOfProductFromSupplier[products][suppliers];
 dvar boolean ProductDeliverFromSupplier[products][suppliers];
 dvar boolean UsedSuppliers[suppliers];
 dvar float quantityOfAreaPerSupplier[suppliers];
 
 // Objective Function
 minimize
    sum(j in suppliers) fixedAdminCost * UsedSuppliers[j]
    + sum(i in products, j in suppliers) coordinationCost * ProductDeliverFromSupplier[i][j]
    + sum(j in suppliers) warehouseCostPerSqm * quantityOfAreaPerSupplier[j]
    + sum(i in products, j in suppliers) productPricePerSupplier[i][j] * quantityOfProductFromSupplier[i][j];
 
 // Constraints 
 
 subject to {

    // R1 – Demand satisfaction: every product demand must be fully met
    forall(i in products)
        ctDemand:
        sum(j in suppliers) quantityOfProductFromSupplier[i][j] == productAnnualDemand[i];

    // R2 – Link x_ij and y_ij: if a product is bought from a supplier, the relationship is active
    forall(i in products, j in suppliers)
        ctLinkXY:
        quantityOfProductFromSupplier[i][j] <= productAnnualDemand[i] * ProductDeliverFromSupplier[i][j];

    // R3 – At most 3 suppliers per product
    forall(i in products)
        ctMaxSuppliersPerProduct:
        sum(j in suppliers) ProductDeliverFromSupplier[i][j] <= 3;

    // R4 – At most 4 suppliers in total
    ctMaxSuppliers:
    sum(j in suppliers) UsedSuppliers[j] <= 4;

    // R5 – Link y_ij and z_j: if a product-supplier relationship is active, the supplier is selected
    forall(i in products, j in suppliers)
        ctLinkYZ:
        ProductDeliverFromSupplier[i][j] <= UsedSuppliers[j];

    // R6 – Reserved area >= 5% of total area associated with that supplier
    forall(j in suppliers)
        ctMinReservedArea:
        quantityOfAreaPerSupplier[j] >= 0.05 *
            sum(i in products) productUnitArea[i] * quantityOfProductFromSupplier[i][j];

    // R7 – Supplier capacity: total area assigned to a supplier cannot exceed its capacity
    forall(j in suppliers)
        ctSupplierCapacity:
        sum(i in products) productUnitArea[i] * quantityOfProductFromSupplier[i][j] <= supplierArea[j];

    // R8 – Total reserved warehouse area cannot exceed hub limit
    ctMaxWarehouseArea:
    sum(j in suppliers) quantityOfAreaPerSupplier[j] <= 4.4;

    // R9 – Conditional constraint: if Gamma supplies UPS 1 kVA,
    //      then Gamma supplies at most 25% of Access Switch and 10% of Mini PC
    ctGammaSwitch:
    quantityOfProductFromSupplier["Access Switch"]["Supplier Gamma"]
        <= 0.25 * productAnnualDemand["Access Switch"]
        + productAnnualDemand["Access Switch"] * (1 - ProductDeliverFromSupplier["UPS 1 kVA"]["Supplier Gamma"]);

    ctGammaMiniPC:
    quantityOfProductFromSupplier["Mini PC"]["Supplier Gamma"]
        <= 0.10 * productAnnualDemand["Mini PC"]
        + productAnnualDemand["Mini PC"] * (1 - ProductDeliverFromSupplier["UPS 1 kVA"]["Supplier Gamma"]);
}
 