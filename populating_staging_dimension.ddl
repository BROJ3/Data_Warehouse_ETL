--- Populating Customer Dimension into Datastaging

INSERT INTO Customer_Dimension (CustomerId,CName,CZip) 
SELECT c.customerid, c.customername, c.customerzip 
FROM crnjakt_zagimore.customer c;

--- Populating Store Dimension into Datastaging

INSERT INTO Store_Dimension (RegionID, RegionName,StoreId,StoreZip)
SELECT s.regionid,r.regionname, s.storeid,s.storezip
FROM crnjakt_zagimore.store as s
JOIN crnjakt_zagimore.region as r
on s.regionid=r.regionid; 

--- Populating Product Dimension into Datastaging for Sales products

INSERT INTO Product_Dimension (ProductId, Productname, ProductSalesPrice, VendorId, Vendorname, categoryID, Categoryname, ProductType)
SELECT p.productid, p.productname , p.productprice, v.vendorid, v.vendorname ,c.categoryid, c.categoryname , 'Sales'
FROM  crnjakt_zagimore.product as p , crnjakt_zagimore.category as c, crnjakt_zagimore.vendor as v 
WHERE c.categoryid = p.categoryid and p.vendorid = v.vendorid;

--- Populating Product Dimension into Datastaging for Rental products

INSERT INTO Product_Dimension (ProductId, Productname, ProductDailyRentalPrice, ProductWeeklyRental, VendorId, Vendorname, categoryID, Categoryname, ProductType)
SELECT p.productid, p.productname , p.productpricedaily, p.productpriceweekly, v.vendorid, v.vendorname ,c.categoryid, c.categoryname , 'Rental'
FROM  crnjakt_zagimore.rentalProducts as p , crnjakt_zagimore.category as c, crnjakt_zagimore.vendor as v 
WHERE c.categoryid = p.categoryid and p.vendorid = v.vendorid; 

--- Extracting fact in datastaging and creating a temporary table

CREATE TABLE IntermediateFact as
SELECT sv.noofitems as UnitSold , p.productprice * sv.noofitems as RevenueGenerated , 'Sales' as RevenueType , sv.tid as TID , 
p.productid as ProductId , c.customerid as CustomerId , s.storeid as StoreId , st.tdate as FullDate  
FROM crnjakt_zagimore.product as p , crnjakt_zagimore.soldvia sv , crnjakt_zagimore.customer as c , crnjakt_zagimore.store as s , crnjakt_zagimore.salestransaction as st
WHERE sv.productid = p.productid 
AND sv.tid = st.tid
AND st.customerid = c.customerid 
AND s.storeid = st.storeid;

--- Populating fact table using the IntermediateFact table and joining all the dimensions

INSERT INTO Revenue (UnitSold, RevenueGenerated,RevenueType, TID, CustomerKey,StoreKey, ProductKey, Calendar_Key )
SELECT i.UnitSold , i.RevenueGenerated , i.RevenueType, i.TID, cd.CustomerKey , sd.StoreKey , pd.ProductKey , cad.Calendar_Key
FROM IntermediateFact as i , Customer_Dimension as cd, Store_Dimension as sd, Product_Dimension as pd, Calendar_Dimension as cad
WHERE i.CustomerId = cd.CustomerId
AND sd.StoreId = i.StoreId
AND pd.ProductId = i.ProductId 
AND pd.ProductType = 'Sales'
AND cad.FullDate = i.FullDate;

-- Populating the fact table with rental facts
-- Weekly Facts
select 0 as unitSold, p.productpriceweekly * rv.duration as RevenueGenerated, 'RentalWeekly' as revenueType,
rv.tid as TID, p.productid as productId, c.customerid as customerId, s.storeid as storeid, rt.tdate as calendar
from crnjakt_zagimore.rentalProducts as p , crnjakt_zagimore.rentvia as rv, crnjakt_zagimore.store as s, crnjakt_zagimore.rentaltransaction as rt, crnjakt_zagimore.customer as c
where p.productid= rv.productid and rt.tid = rv.tid and rt.customerid = c.customerid and s.storeid = rt.storeid and rv.rentalType ='w';

-- Daily Facts
insert into intermediateFact(unitSold, RevenueGenerated,revenueType,TID,productID,customerId, storeid, calendar)
select 0 as unitSold, p.productpricedaily * rv.duration as RevenueGenerated, 'RentalDaily' as revenueType,
rv.tid as TID, p.productid as productId, c.customerid as customerId, s.storeid as storeid, rt.tdate as calendar
from crnjakt_zagimore.rentalProducts as p , crnjakt_zagimore.rentvia as rv, crnjakt_zagimore.store as s, crnjakt_zagimore.rentaltransaction as rt, crnjakt_zagimore.customer as c
where p.productid= rv.productid and rt.tid = rv.tid and rt.customerid = c.customerid and s.storeid = rt.storeid and rv.rentalType ='D';

insert into Revenue_and_unit_sold(unitSold, RevenueGenerated,revenueType,TID,productKey,customerKey, storeKey, calendarKey)
select i.unitSold, i.RevenueGenerated, i.revenueType, i.TID, pd.productKey, cd.customerKey, sd.storeKey, cad.calendarKey
from intermediateFact as i, Customer_Dimension as cd, Store_Dimension as sd, Product_Dimension as pd, Calendar_Dimension as cad
where i.customerId = cd.custId and sd.storeId = i.storeid and pd.productID = i.productId and pd.productType ='Rental' and cad.FullDate = i.calendar;