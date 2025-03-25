-- Populating Customer Dimension into Datastaging
INSERT INTO staging.Customer_Dimension (CustomerId, CName, CZip)
SELECT c.customerid, c.customername, c.customerzip
FROM zagimore.customer c;

-- Populating Store Dimension into Datastaging
INSERT INTO staging.Store_Dimension (RegionID, RegionName, StoreId, StoreZip)
SELECT s.regionid, r.regionname, s.storeid, s.storezip
FROM zagimore.store s, zagimore.region r
WHERE s.regionid = r.regionid;

-- Populating Product Dimension for Sales products
INSERT INTO staging.Product_Dimension (ProductId, Productname, ProductSalesPrice, VendorId, Vendorname, categoryID, Categoryname, ProductType)
SELECT p.productid, p.productname, p.productprice, v.vendorid, v.vendorname, c.categoryid, c.categoryname, 'Sales'
FROM zagimore.product p, zagimore.category c, zagimore.vendor v
WHERE c.categoryid = p.categoryid 
  AND p.vendorid = v.vendorid;

-- Populating Product Dimension for Rental products
INSERT INTO staging.Product_Dimension (ProductId, Productname, ProductDailyRentalPrice, ProductWeeklyRental, VendorId, Vendorname, categoryID, Categoryname, ProductType)
SELECT p.productid, p.productname, p.productpricedaily, p.productpriceweekly, v.vendorid, v.vendorname, c.categoryid, c.categoryname, 'Rental'
FROM zagimore.rentalProducts p, zagimore.category c, zagimore.vendor v
WHERE c.categoryid = p.categoryid 
  AND p.vendorid = v.vendorid;

-- Create a temporary table for intermediate Sales facts
CREATE TABLE staging.IntermediateFact AS
SELECT sv.noofitems AS UnitSold,
       p.productprice * sv.noofitems AS RevenueGenerated,
       'Sales' AS RevenueType,
       sv.tid AS TID,
       p.productid AS ProductId,
       c.customerid AS CustomerId,
       s.storeid AS StoreId,
       st.tdate AS FullDate
FROM zagimore.product p, zagimore.soldvia sv, zagimore.salestransaction st, zagimore.customer c, zagimore.store s
WHERE sv.productid = p.productid 
  AND sv.tid = st.tid
  AND st.customerid = c.customerid 
  AND s.storeid = st.storeid;

-- Populate fact table (Revenue) for Sales facts using the IntermediateFact
INSERT INTO staging.Revenue (UnitSold, RevenueGenerated, RevenueType, TID, CustomerKey, StoreKey, ProductKey, Calendar_Key)
SELECT i.UnitSold,
       i.RevenueGenerated,
       i.RevenueType,
       i.TID,
       cd.CustomerKey,
       sd.StoreKey,
       pd.ProductKey,
       cad.Calendar_Key
FROM staging.IntermediateFact i, staging.Customer_Dimension cd, staging.Store_Dimension sd, staging.Product_Dimension pd, staging.Calendar_Dimension cad
WHERE i.CustomerId = cd.CustomerId

-- Populating Store Dimension into Datastaging
INSERT INTO staging.Store_Dimension (RegionID, RegionName, StoreId, StoreZip)
SELECT s.regionid, r.regionname, s.storeid, s.storezip
FROM zagimore.store s, zagimore.region r
WHERE s.regionid = r.regionid;

-- Populating Product Dimension for Sales products
  AND i.StoreId = sd.StoreId
  AND i.ProductId = pd.ProductId 
  AND pd.ProductType = 'Sales'
  AND i.FullDate = cad.FullDate;


-- Insert Rental Weekly facts into IntermediateFact
INSERT INTO staging.IntermediateFact (UnitSold, RevenueGenerated, RevenueType, TID, ProductId, CustomerId, StoreId, FullDate)
SELECT 0 AS UnitSold,
       p.productpriceweekly * rv.duration AS RevenueGenerated,
       'RentalWeekly' AS RevenueType,
       rv.tid AS TID,
       p.productid AS ProductId,
       c.customerid AS CustomerId,
       s.storeid AS StoreId,
       rt.tdate AS FullDate
FROM zagimore.rentalProducts p, zagimore.rentvia rv, zagimore.rentaltransaction rt, zagimore.customer c, zagimore.store s
WHERE p.productid = rv.productid
  AND rt.tid = rv.tid
  AND rt.customerid = c.customerid
  AND s.storeid = rt.storeid
  AND rv.rentalType = 'W';

-- Insert Rental Daily facts into IntermediateFact
INSERT INTO staging.IntermediateFact (UnitSold, RevenueGenerated, RevenueType, TID, ProductId, CustomerId, StoreId, FullDate)
SELECT 0 AS UnitSold,
       p.productpricedaily * rv.duration AS RevenueGenerated,
       'RentalDaily' AS RevenueType,
       rv.tid AS TID,
       p.productid AS ProductId,
       c.customerid AS CustomerId,
       s.storeid AS StoreId,
       rt.tdate AS FullDate
FROM zagimore.rentalProducts p, zagimore.rentvia rv, zagimore.rentaltransaction rt, zagimore.customer c, zagimore.store s
WHERE p.productid = rv.productid
  AND rt.tid = rv.tid
  AND rt.customerid = c.customerid
  AND s.storeid = rt.storeid
  AND rv.rentalType = 'D';

-- Finally, populate the rental fact table (Revenue)
INSERT INTO staging.Revenue (UnitSold, RevenueGenerated, RevenueType, TID, ProductKey, CustomerKey, StoreKey, Calendar_Key)
SELECT i.UnitSold,
       i.RevenueGenerated,
       i.RevenueType,
       i.TID,
       pd.ProductKey,
       cd.CustomerKey,
       sd.StoreKey,
       cad.Calendar_Key
FROM staging.IntermediateFact i, staging.Customer_Dimension cd, staging.Store_Dimension sd, staging.Product_Dimension pd, staging.Calendar_Dimension cad
WHERE i.CustomerId = cd.CustomerId
  AND i.StoreId = sd.StoreId
  AND i.ProductId = pd.ProductId 
  AND pd.ProductType = 'Rental'
  AND i.FullDate = cad.FullDate
  AND i.RevenueType IN ('RentalWeekly', 'RentalDaily');
