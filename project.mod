/*********************************************
 * OPL 22.1.2.0 Model
 * Author: minig
 * Creation Date: 08/05/2026 at 03:12:58
 *********************************************/

 {string} products = ...;
 {string} suppliers = ...;
 
 int productPricePerSupplier[products][suppliers] = ...;
 int productAnnualDemand[products] = ...;
 float productUnitArea[products] = ...;
 float supplierArea[suppliers] = ...;
 
 dvar int+ quantityOfProductFromSupplier[products][suppliers];
 dvar boolean ProductDeliverFromSupplier[products][suppliers];