--check for new stores
CREATE procedure DailyStoreRefresh()
BEGIN

INSERT INTO Store_Dimension(StoreId,StoreZip,RegioniD,RegionName,ExtractionTimestamp, PDLoaded, DVF,DVU, CurrentStatus)
SELECT s.storeid, s.storezip, r.regionid, r.regionname,NOW(),False, NOW(), '2040-01-01','C'
FROM crnjakt_zagimore.store s, crnjakt_zagimore.region r
WHERE s.regionid = r.regionid
AND s.StoreId not in (SELECT StoreId FROM crnjakt_zagimore_ds.Store_Dimension);

INSERT INTO crnjakt_zagimore_dw.Store_Dimension (StoreKey, StoreId,StoreZip,RegioniD,RegionName, DVF,DVU, CurrentStatus)
SELECT StoreKey, StoreId,StoreZip,RegioniD,RegionName,DVF,DVU, CurrentStatus
from Store_Dimension
WHERE PDLoaded=False;

UPDATE Store_Dimension
SET PDLoaded=True;
END


--check for new products
CREATE procedure DailyProductRefresh()
BEGIN

INSERT INTO Product_Dimension (ProductId, Productname, ProductSalesPrice, VendorId, Vendorname, categoryID, Categoryname, ProductType, ExtractionTimestamp, PDLoaded, DVF, DVU, CurrentStatus)
SELECT p.productid, p.productname , p.productprice, v.vendorid, v.vendorname ,c.categoryid, c.categoryname , 'SalesProduct', NOW(), False, NOW(), '2040-01-01', 'C'
FROM  crnjakt_zagimore.product as p , crnjakt_zagimore.category as c, crnjakt_zagimore.vendor as v 
WHERE c.categoryid = p.categoryid and p.vendorid = v.vendorid
AND p.productid not in (SELECT ProductId FROM Product_Dimension WHERE ProductType = 'SalesProduct');

INSERT INTO Product_Dimension (ProductId, Productname, ProductDailyRentalPrice, ProductWeeklyRental, VendorId, Vendorname, categoryID, Categoryname, ProductType, ExtractionTimestamp, PDLoaded, DVF, DVU, CurrentStatus)
SELECT p.productid, p.productname , p.productpricedaily, p.productpriceweekly, v.vendorid, v.vendorname ,c.categoryid, c.categoryname , 'RentalProduct', NOW(), False, NOW(), '2040-01-01', 'C'
FROM  crnjakt_zagimore.rentalProducts as p , crnjakt_zagimore.category as c, crnjakt_zagimore.vendor as v 
WHERE c.categoryid = p.categoryid and p.vendorid = v.vendorid
AND p.productid not in (SELECT ProductId FROM Product_Dimension WHERE ProductType = 'RentalProduct');

INSERT INTO crnjakt_zagimore_dw.Product_Dimension (ProductKey, ProductId, Productname, ProductSalesPrice, ProductDailyRentalPrice, ProductWeeklyRental,VendorId, Vendorname, categoryID, Categoryname, ProductType, DVF, DVU, CurrentStatus)
SELECT ProductKey, ProductId, Productname, ProductSalesPrice,ProductDailyRentalPrice, ProductWeeklyRental, VendorId, Vendorname, categoryID, Categoryname, ProductType, DVF, DVU, CurrentStatus
from Product_Dimension
WHERE PDLoaded=False;

UPDATE Product_Dimension
SET PDLoaded=True;
END

--check for new customers
CREATE procedure DailyCustomerRefresh()
BEGIN

INSERT INTO crnjakt_zagimore_ds.Customer_Dimension (CName, CZip, CustomerId, ExtractionTimestamp, PDLoaded, DVF, DVU, CurrentStatus)
SELECT c.customername, c.customerzip, c.customerid, NOW(), False, NOW(), '2040-01-01', 'C'
FROM crnjakt_zagimore.customer c
WHERE c.customerId not in (SELECT CustomerId FROM crnjakt_zagimore_ds.Customer_Dimension);

INSERT INTO crnjakt_zagimore_dw.Customer_Dimension (CustomerKey, CName, CZip, CustomerId, DVF, DVU, CurrentStatus)
SELECT CustomerKey, CName, CZip, CustomerId, DVF, DVU, CurrentStatus
from Customer_Dimension
WHERE PDLoaded=False;

UPDATE Customer_Dimension
SET PDLoaded=True;
END

CREATE PROCEDURE Daily_Regular_Fact_Refresh()
BEGIN
DROP Table IntermediateFactTable;
CREATE TABLE IntermediateFactTable AS 
SELECT sv.noofitems AS UnitSolds, p.productprice * sv.noofitems AS RevenueGenerated, "SalesTransaction" AS RevenueType, sv.tid 
AS TID, p.productid AS productId, st.customerid AS customerId, st.storeid AS storeId, st.tdate AS fullDate 
FROM crnjakt_zagimore.product p, crnjakt_zagimore.soldvia sv, crnjakt_zagimore.salestransaction st 
WHERE sv.productid = p.productid 
AND sv.tid=st.tid
AND st.tdate >(SELECT MAX(DATE(ExtractionTimestamp))
FROM Revenue );

ALTER TABLE IntermediateFactTable
MODIFY RevenueType VARCHAR(25);

INSERT INTO IntermediateFactTable (UnitSolds, RevenueGenerated, RevenueType, TID, productId, customerId, storeId, fullDate)
SELECT 0 AS UnitSolds, r.productpriceweekly * rv.duration AS RevenueGenerated, "RentalDaily" AS RevenueType, rv.tid 
AS TID, r.productid AS produtId, c.customerid AS customerId, s.storeid AS storeId, rt.tdate AS fullDate 
FROM crnjakt_zagimore.rentalProducts r, crnjakt_zagimore.rentvia rv, 
crnjakt_zagimore.customer c, crnjakt_zagimore.store s, crnjakt_zagimore.rentaltransaction rt 
WHERE rv.productid = r.productid 
AND rv.tid=rt.tid 
AND c.customerid=rt.customerid 
AND s.storeid = rt.storeid
AND rv.rentaltype= 'D'
AND rt.tdate >(SELECT MAX(DATE(ExtractionTimestamp))
FROM Revenue );

INSERT INTO IntermediateFactTable (UnitSolds, RevenueGenerated, RevenueType, TID, productId, customerId, storeId, fullDate)
SELECT 0 AS UnitSolds, r.productpriceweekly * rv.duration AS RevenueGenerated, "RentalWeekly" AS RevenueType, rv.tid 
AS TID, r.productid AS produtId, c.customerid AS customerId, s.storeid AS storeId, rt.tdate AS fullDate 
FROM crnjakt_zagimore.rentalProducts r, crnjakt_zagimore.rentvia rv, 
crnjakt_zagimore.customer c, crnjakt_zagimore.store s, crnjakt_zagimore.rentaltransaction rt 
WHERE rv.productid = r.productid 
AND rv.tid=rt.tid 
AND c.customerid=rt.customerid 
AND s.storeid = rt.storeid
AND rv.rentaltype= 'W'
AND rt.tdate >(SELECT MAX(DATE(ExtractionTimestamp))
FROM Revenue );

INSERT INTO Revenue (UnitSolds, RevenueGenerated,RevenueType, TID, 
CustomerKey,StoreKey, ProductKey, Calendar_Key, ExtractionTimestamp, f_loaded )
SELECT i.UnitSolds , i.RevenueGenerated , i.RevenueType, 
i.TID, cd.CustomerKey , sd.StoreKey , pd.ProductKey , cad.Calendar_Key,NOW()+ INTERVAL 1 DAY, FALSE 
FROM IntermediateFactTable as i , Customer_Dimension as cd,
Store_Dimension as sd, Product_Dimension as pd, Calendar_Dimension as cad
WHERE i.CustomerId = cd.CustomerId
AND sd.StoreId = i.StoreId
AND pd.ProductId = i.ProductId 
AND cad.FullDate = i.FullDate
AND LEFT(pd.ProductType, 1) = LEFT (i.RevenueType, 1);

INSERT INTO crnjakt_zagimore_dw.Revenue
(Calendar_Key, CustomerKey, ProductKey, RevenueGenerated,  
RevenueType, StoreKey, TID, UnitSolds)
SELECT Calendar_Key, CustomerKey, ProductKey, RevenueGenerated,  
RevenueType, StoreKey, TID, UnitSolds
FROM Revenue
WHERE f_loaded = 0;

UPDATE Revenue 
SET f_loaded = True 
WHERE f_loaded = False;
END;

CREATE PROCEDURE LateFactRefresh()
BEGIN
DROP TABLE IF EXISTS IntermediateFactTable;
CREATE TABLE IntermediateFactTable AS
SELECT sv.noofitems as UnitSold , p.productprice * sv.noofitems as
RevenueGenerated , 'SalesTransaction' as RevenueType , sv.tid as TID ,
p.productid as ProductId , st.customerid as CustomerId , st.storeid as
StoreId , st.tdate as FullDate
FROM crnjakt_zagimore.product as p , crnjakt_zagimore.soldvia sv ,
crnjakt_zagimore.salestransaction as st
WHERE sv.productid = p.productid
AND sv.tid = st.tid
AND st.tid NOT IN (SELECT TID FROM Revenue WHERE RevenueType = 'SalesTransaction');

ALTER TABLE IntermediateFactTable
MODIFY RevenueType VARCHAR(25);

INSERT INTO IntermediateFactTable(UnitSold,RevenueGenerated,RevenueType,TID,ProductId,CustomerId,StoreId,FullDate)
SELECT 0 as UnitSolds ,r.productpricedaily * rv.duration as RevenueGenerated , 'RentalDaily' as RevenueType , rv.tid as TID ,
r.productid as ProductId , c.customerid as CustomerId , s.storeid as StoreId , rt.tdate as FullDate
FROM crnjakt_zagimore.rentalProducts as r , crnjakt_zagimore.rentvia rv , crnjakt_zagimore.customer as c , crnjakt_zagimore.store as s , crnjakt_zagimore.rentaltransaction as rt
WHERE rv.productid = r.productid AND rv.tid = rt.tid AND rt.customerid = c.customerid AND s.storeid = rt.storeid AND rv.rentaltype='D' AND rt.tid NOT IN (SELECT TID FROM Revenue WHERE RevenueType LIKE 'R%');

INSERT INTO IntermediateFactTable(UnitSold,RevenueGenerated,RevenueType,TID,ProductId,CustomerId,StoreId,FullDate)
SELECT 0 as UnitSold , r.productpricedaily * rv.duration as RevenueGenerated , 'RentalWeekly' as RevenueType , rv.tid as TID , r.productid as ProductId , 
c.customerid as CustomerId , s.storeid as StoreId , rt.tdate as FullDate
FROM crnjakt_zagimore.rentalProducts as r , crnjakt_zagimore.rentvia rv , crnjakt_zagimore.customer as c , crnjakt_zagimore.store as s , crnjakt_zagimore.rentaltransaction as rt
WHERE rv.productid = r.productid AND rv.tid = rt.tid AND rt.customerid = c.customerid AND s.storeid = rt.storeid
AND rv.rentaltype='W' AND rt.tid NOT IN (SELECT TID FROM Revenue WHERE RevenueType LIKE 'R%');

INSERT INTO Revenue (UnitSolds, RevenueGenerated,RevenueType, TID,CustomerKey,StoreKey, ProductKey,Calendar_Key,ExtractionTimestamp,f_loaded )
SELECT i.UnitSold , i.RevenueGenerated , i.RevenueType, i.TID, cd.CustomerKey , sd.StoreKey , pd.ProductKey , cad.Calendar_Key, NOW(), False
FROM IntermediateFactTable as i , Customer_Dimension as cd, Store_Dimension as sd, Product_Dimension as pd, Calendar_Dimension as cad
WHERE i.CustomerId = cd.CustomerId AND sd.StoreId = i.StoreId AND pd.ProductId = i.ProductId AND cad.FullDate = i.FullDate 
AND LEFT(pd.ProductType,1)=LEFT(i.RevenueType,1);

INSERT INTO crnjakt_zagimore_dw.Revenue( RevenueGenerated,UnitSolds,RevenueType,TID,CustomerKey,StoreKey,ProductKey,Calendar_Key)
SELECT RevenueGenerated,UnitSolds,RevenueType,TID,CustomerKey,StoreKey,ProductKey,Calendar_Key
FROM Revenue
WHERE f_loaded=0;

UPDATE Revenue
SET f_loaded = 1
WHERE f_loaded = 0;

END



CREATE PROCEDURE PRODUCT_DIMENSION_TYPE2_REFRESH()
BEGIN

DROP TABLE IF EXISTS IPD;
CREATE TABLE IPD AS
SELECT p.productid, pd.ProductType
FROM crnjakt_zagimore.product p, crnjakt_zagimore.category c, crnjakt_zagimore.vendor v, crnjakt_zagimore_ds.Product_Dimension pd 
WHERE c.categoryid=p.categoryid 
AND p.vendorid=v.vendorid 
AND pd.productid=p.productid 
AND pd.ProductType='SalesProduct' 
AND( p.productprice != pd.ProductSalesPrice OR p.Productname != pd.Productname OR p.VendorId!= pd.VendorId) AND pd.CurrentStatus = 'C';

UPDATE Product_Dimension  SET DVU = DATE(NOW()) -INTERVAL 1 DAY, CurrentStatus = 'N'
WHERE ProductId IN (SELECT productid  FROM IPD WHERE ProductType='SalesProduct') AND ProductType = 'SalesProduct';

INSERT INTO IPD (productid,ProductType)
SELECT p.productid, pd.ProductType
FROM crnjakt_zagimore.product p, crnjakt_zagimore.category c, crnjakt_zagimore.vendor v, crnjakt_zagimore_ds.Product_Dimension pd 
WHERE c.categoryid=p.categoryid 
AND p.vendorid=v.vendorid 
AND pd.productid=p.productid 
AND pd.ProductType='RentalProduct' 
AND( p.productprice != pd.ProductSalesPrice OR p.Productname != pd.Productname OR p.VendorId!= pd.VendorId) AND pd.CurrentStatus = 'C';

UPDATE Product_Dimension  SET DVU = DATE(NOW()) -INTERVAL 1 DAY, CurrentStatus = 'N'
WHERE ProductId IN (SELECT productid FROM IPD WHERE ProductType='RentalProduct') AND ProductType = 'RentalProduct';

INSERT INTO Product_Dimension (ProductId, Productname, ProductSalesPrice, VendorId, Vendorname, categoryID, Categoryname, ProductType,ExtractionTimestamp, PDLoaded,DVF,DVU,CurrentStatus)
SELECT p.productid, p.productname , p.productprice, v.vendorid, v.vendorname ,c.categoryid, c.categoryname , 'SalesProduct', NOW(), False, NOW(), '2040-01-01', 'C' 
FROM crnjakt_zagimore.product as p , crnjakt_zagimore.category as c, crnjakt_zagimore.vendor as v 
WHERE c.categoryid = p.categoryid 
and p.vendorid = v.vendorid 
AND p.productid in (SELECT productid FROM IPD);

ALTER TABLE crnjakt_zagimore_dw.Revenue
DROP FOREIGN KEY Revenue_ibfk_5;

Replace INTO crnjakt_zagimore_dw.Product_Dimension (ProductKey, ProductId, Productname, ProductSalesPrice, ProductDailyRentalPrice, ProductWeeklyRental,VendorId, Vendorname, categoryID, Categoryname, ProductType , dvf , dvu , currentstatus)
SELECT ProductKey, ProductId, Productname, ProductSalesPrice,ProductDailyRentalPrice, ProductWeeklyRental, VendorId, Vendorname, categoryID, Categoryname, ProductType , dvf , dvu , currentstatus
from Product_Dimension; 

ALTER TABLE crnjakt_zagimore_dw.Revenue
ADD CONSTRAINT Revenue_ibfk_5
FOREIGN KEY (ProductKey)
REFERENCES crnjakt_zagimore_dw.Product_Dimension(ProductKey);

UPDATE Product_Dimension
SET PDloaded= TRUE 
WHERE PDloaded= FALSE;

END

CREATE PROCEDURE STORE_TYPE2_REFRESH()
BEGIN
DROP TABLE IF EXISTS SPD;
CREATE TABLE SPD AS
SELECT s.storeId, s.storeZip, r.RegioniD, r.RegionName, NOW() AS ExtractionTimeStamp, FALSE AS PDLoaded, NOW() AS DVF, '2040-01-01' AS DVU, 'C' AS CurrentStatus 
FROM crnjakt_zagimore.store s, crnjakt_zagimore.region r,crnjakt_zagimore_ds.Store_Dimension sd 
WHERE (s.storeid != sd.StoreId OR s.storezip != sd.storeZip) 
AND s.storeid = sd.storeId 
AND s.RegionID = r.RegionID 
AND sd.CurrentStatus = 'C';

UPDATE Store_Dimension sd, SPD
SET sd.DVU = NOW() - INTERVAL 1 DAY, sd.CurrentStatus = 'N'
WHERE sd.storeId = SPD.storeId AND sd.CurrentStatus = 'C';

INSERT INTO Store_Dimension(storeId, storeZip, RegioniD, RegionName, ExtractionTimeStamp, PDLoaded, DVF, DVU, CurrentStatus)
SELECT storeid, storeZip, RegioniD, RegionName ,ExtractionTimeStamp, PDLoaded, DVF, DVU, CurrentStatus
FROM SPD;

ALTER TABLE crnjakt_zagimore_dw.Revenue 
DROP FOREIGN KEY Revenue_ibfk_2;

ALTER TABLE crnjakt_zagimore_dw.DailyStoreSnapshot
DROP FOREIGN KEY DailyStoreSnapshot_ibfk_3;

ALTER TABLE crnjakt_zagimore_dw.OneWayAggregateByProductCategory
DROP FOREIGN KEY OneWayAggregateByProductCategory_ibfk_3;

REPLACE INTO crnjakt_zagimore_dw.Store_Dimension (StoreKey, StoreId, StoreZip, RegioniD, RegionName, DVF, DVU, CurrentStatus)
SELECT StoreKey,storeid, storeZip, RegioniD, RegionName, DVF, DVU, CurrentStatus
FROM Store_Dimension;

ALTER TABLE crnjakt_zagimore_dw.Revenue
ADD CONSTRAINT Revenue_ibfk_2
FOREIGN KEY (StoreKey) REFERENCES crnjakt_zagimore_dw.Store_Dimension(StoreKey);

ALTER TABLE crnjakt_zagimore_dw.DailyStoreSnapshot
ADD CONSTRAINT DailyStoreSnapshot_ibfk_3
FOREIGN KEY (StoreKey) REFERENCES crnjakt_zagimore_dw.Store_Dimension(StoreKey);

ALTER TABLE crnjakt_zagimore_dw.OneWayAggregateByProductCategory
ADD CONSTRAINT OneWayAggregateByProductCategory_ibfk_3
FOREIGN KEY (StoreKey) REFERENCES crnjakt_zagimore_dw.Store_Dimension(StoreKey);

UPDATE Store_Dimension SET PDLoaded = 1 WHERE PDLoaded = 0;
END 


CREATE PROCEDURE CUSTOMER_TYPE2_REFRESH()
BEGIN

DROP TABLE IF EXISTS CPD;
CREATE TABLE CPD AS
SELECT c.customerid, c.customername, c.customerzip, NOW() AS ExtractionTimeStamp, FALSE AS PDLoaded, NOW() AS DVF, '2040-01-01' AS DVU, 'C' AS CurrentStatus 
FROM crnjakt_zagimore.customer c, crnjakt_zagimore_ds.Customer_Dimension cd 
WHERE (c.customername != cd.CName OR c.customerzip != cd.CZip) 
AND c.customerid = cd.CustomerId 
AND cd.CurrentStatus = 'C';

UPDATE Customer_Dimension cd, CPD
SET cd.DVU = NOW() - INTERVAL 1 DAY, cd.CurrentStatus = 'N'
WHERE cd.CustomerId = CPD.CustomerId AND cd.CurrentStatus = 'C';

INSERT INTO Customer_Dimension(CName, CZip, customerid,ExtractionTimeStamp, PDLoaded, DVF, DVU, CurrentStatus)
SELECT customername, customerzip, customerid,ExtractionTimeStamp, PDLoaded, DVF, DVU, CurrentStatus
FROM CPD;

ALTER TABLE crnjakt_zagimore_dw.Revenue 
DROP FOREIGN KEY Revenue_ibfk_1;

ALTER TABLE crnjakt_zagimore_dw.OneWayAggregateByProductCategory
DROP FOREIGN KEY OneWayAggregateByProductCategory_ibfk_2;

REPLACE INTO crnjakt_zagimore_dw.Customer_Dimension (CustomerKey, CName, CZip, customerid,DVF, DVU, CurrentStatus)
SELECT CustomerKey, CName, CZip, customerid, DVF, DVU, CurrentStatus
FROM Customer_Dimension;

ALTER TABLE crnjakt_zagimore_dw.Revenue
ADD CONSTRAINT Revenue_ibfk_1
FOREIGN KEY (CustomerKey) REFERENCES crnjakt_zagimore_dw.Customer_Dimension(CustomerKey);

ALTER TABLE crnjakt_zagimore_dw.OneWayAggregateByProductCategory
ADD CONSTRAINT OneWayAggregateByProductCategory_ibfk_2
FOREIGN KEY (CustomerKey) REFERENCES crnjakt_zagimore_dw.Customer_Dimension(CustomerKey);

UPDATE Customer_Dimension SET PDLoaded = 1 WHERE PDLoaded = 0;

END