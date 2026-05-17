minigonga
minigonga
:neutral_face: Gameplay?

Este é o começo do canal #otimizacao. 
minigonga — 22:21
/*********************************************
 * OPL 22.1.2.0 Data
 * Author: minig
 * Creation Date: 08/05/2026 at 03:12:58
 *********************************************/

 products = {"Enterprise Router", "Access Switch", "Wi-Fi Access Point", "IP Camera", "UPS 1 kVA", "Mini PC"};
 suppliers = {"Supplier Alpha", "Supplier Beta", "Supplier Gamma", "Supplier Delta", "Supplier Epsilon"};
 
 productPricePerSupplier = [[470, 455, 462, 480, 468], 
                             [320, 332, 315, 325, 318], 
                             [118, 121, 125, 116, 119], 
                             [92, 89, 94, 91, 87],
                             [410, 395, 380, 402, 415], 
                             [510, 522, 500, 508, 495]];
 
 productAnnualDemand = [120, 100, 180, 160, 70, 90];
 productUnitArea = [0.12, 0.10, 0.06, 0.08, 0.30, 0.18];
 supplierArea = [24.0, 23.0, 22.5, 20.5, 23.5];
 
 fixedAdminCost = 1500;
 coordinationCost = 700;
 warehouseCostPerSqm = 300;
 
 //Penalty
 
 supplierOverflowPenalty = 100;
 
minigonga — 22:36
/*********************************************
 * OPL 22.1.2.0 Model
 * Author: minig
 * Creation Date: 08/05/2026 at 03:12:58
 *********************************************/

message.txt
7 KB
﻿
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
 
 // Penalty
 float supplierOverflowPenalty = ...;
 
 // Decision variables
 dvar int+ quantityOfProductFromSupplier[products][suppliers];
 dvar boolean ProductDeliverFromSupplier[products][suppliers];
 dvar boolean UsedSuppliers[suppliers];
 dvar float quantityOfAreaPerSupplier[suppliers];
 dvar float supplierOverflow[suppliers]; // Variable to soften the constraint
 
 // Objective Function
 minimize
    sum(j in suppliers) fixedAdminCost * UsedSuppliers[j]
    + sum(i in products, j in suppliers) coordinationCost * ProductDeliverFromSupplier[i][j]
    + sum(j in suppliers) warehouseCostPerSqm * quantityOfAreaPerSupplier[j]
    + sum(i in products, j in suppliers) productPricePerSupplier[i][j] * quantityOfProductFromSupplier[i][j]
 	+ sum(j in suppliers) supplierOverflowPenalty * supplierOverflow[j];
 
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
        sum(i in products) productUnitArea[i] * quantityOfProductFromSupplier[i][j] <= supplierArea[j] + supplierOverflow[j];

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
        
    forall(j in suppliers)
      overflowPositive:
      supplierOverflow[j] >= 0;
}

// ======================================================
// RESULTS
// ======================================================

execute {

   writeln("\n========== SOLUTION ==========\n");

   writeln("OBJECTIVE VALUE = ", cplex.getObjValue());

   // --------------------------------------------------
   // Cost breakdown
   // --------------------------------------------------

   var adminCost = 0;
   var coordCost = 0;
   var warehouseCost = 0;
   var purchasingCost = 0;

   for(var j in suppliers) {
      adminCost += fixedAdminCost * UsedSuppliers[j];
      warehouseCost += warehouseCostPerSqm * quantityOfAreaPerSupplier[j];
   }

   for(var i in products) {
      for(var j in suppliers) {

         coordCost +=
            coordinationCost * ProductDeliverFromSupplier[i][j];

         purchasingCost +=
            productPricePerSupplier[i][j] *
            quantityOfProductFromSupplier[i][j];
      }
   }

   writeln("\n--- COST BREAKDOWN ---");

   writeln("Administrative Cost = ", adminCost);
   writeln("Coordination Cost   = ", coordCost);
   writeln("Warehouse Cost      = ", warehouseCost);
   writeln("Purchasing Cost     = ", purchasingCost);

   // --------------------------------------------------
   // KPI SUMMARY
   // --------------------------------------------------

   var numSuppliers = 0;
   var numRelationships = 0;
   var totalWarehouseArea = 0;

   for(var j in suppliers) {

      numSuppliers += UsedSuppliers[j];

      totalWarehouseArea +=
         quantityOfAreaPerSupplier[j];
   }

   for(var i in products) {
      for(var j in suppliers) {

         numRelationships +=
            ProductDeliverFromSupplier[i][j];
      }
   }

   writeln("\n--- KPI SUMMARY ---");

   writeln("Selected Suppliers      = ", numSuppliers);
   writeln("Active Relationships    = ", numRelationships);
   writeln("Reserved Warehouse Area = ", totalWarehouseArea);

   // --------------------------------------------------
   // Supplier usage
   // --------------------------------------------------

   writeln("\n--- SELECTED SUPPLIERS ---");

   for(var j in suppliers) {

      if(UsedSuppliers[j] > 0.5) {

         writeln(j);
      }
   }

   // --------------------------------------------------
   // Product allocations
   // --------------------------------------------------

   writeln("\n--- PRODUCT ALLOCATIONS ---");

   for(var i in products) {

      writeln("\nProduct: ", i);

      for(var j in suppliers) {

         if(quantityOfProductFromSupplier[i][j] > 0.001) {

            writeln(
               "   ",
               j,
               " -> ",
               quantityOfProductFromSupplier[i][j]
            );
         }
      }
   }
} 