
CREATE TABLE Customer_Dimension
(
  CustomerKey INT AUTO_INCREMENT,
  CName VARCHAR(15) NOT NULL,
  CZip CHAR(5) NOT NULL,
  CustomerId CHAR(7) NOT NULL,
  PRIMARY KEY (CustomerKey)
);

CREATE TABLE Store_Dimension
(
  StoreKey INT AUTO_INCREMENT,
  StoreId VARCHAR(3) NOT NULL,
  StoreZip CHAR(5) NOT NULL,
  RegioniD CHAR(1) NOT NULL,
  RegionName VARCHAR(25) NOT NULL,
  PRIMARY KEY (StoreKey)
);

CREATE TABLE Product_Dimension
(
  ProductKey INT AUTO_INCREMENT,
  Productname VARCHAR(25) NOT NULL,
  VendorId CHAR(2) NOT NULL,
  Vendorname VARCHAR(25) NOT NULL,
  Categoryname VARCHAR(25) NOT NULL,
  categoryID CHAR(2) NOT NULL,
  ProductSalesPrice Decimal(7,2),
  ProductDailyRentalPrice Decimal(7,2),
  ProductWeeklyRental Decimal(7,2),
  ProductType VARCHAR(10) NOT NULL,
  ProductId Char(3) NOT NULL,
  PRIMARY KEY (ProductKey)
);

CREATE TABLE Calendar_Dimension
(
  Calendar_Key INT AUTO_INCREMENT,
  FullDate DATE NOT NULL,
  MonthYear INT,
  Year INT,
  PRIMARY KEY (Calendar_Key)
);

 CREATE TABLE Revenue
(
  RevenueGenerated INT NOT NULL,
  UnitSold INT NOT NULL,
  RevenueType VARCHAR(20) NOT NULL,
  TID VARCHAR(8) NOT NULL,
  CustomerKey INT NOT NULL,
  StoreKey INT NOT NULL,
  ProductKey INT NOT NULL,
  Calendar_Key INT NOT NULL,
  PRIMARY KEY (RevenueType, TID, CustomerKey, StoreKey, ProductKey, Calendar_Key)
);

-- CHANGE DELIMITER TO $$ -- CALL populateCalendar() Afterwards
CREATE PROCEDURE populateCalendar()
BEGIN
    DECLARE i INT DEFAULT 0;
myloop:
LOOP
INSERT INTO Calendar_Dimension(FullDate)
SELECT DATE_ADD('2013-01-01', INTERVAL i DAY);
SET i=i+1;
IF i=10000 then
LEAVE myloop;
END
IF;
END LOOP myloop;
UPDATE Calendar_Dimension
SET MonthYear = MONTH(FullDate), Year = YEAR(FullDate);
END;


-- populating data staging
--extracting from customer
INSERT INTO Customer_Dimension(CustomerId, CName, CZip)
SELECT c.customerid, c.customername, c.customerzip
FROM crnjakt_zagimore.customer c;

--extracting from store dimension
INSERT INTO Store_Dimension(StoreId,StoreZip,RegioniD,RegionName)
SELECT s.storeid, s.storezip, r.regionid, r.regionname
FROM crnjakt_zagimore.store s, crnjakt_zagimore.region r
WHERE s.regionid = r.regionid;

--Populating sales products in product dimension
INSERT INTO Product_Dimension (ProductName, VendorID, Vendorname, Categoryname, categoryID, ProductSalesPrice, ProductType,ProductId) 
SELECT  p.productname, v.vendorid, v.vendorname , c.categoryname, c.categoryid, p.productprice, "Sales", p.productid
FROM crnjakt_zagimore.product p, crnjakt_zagimore.vendor v, crnjakt_zagimore.category c
WHERE p.categoryid = c.categoryid AND p.vendorid = v.vendorid;

--Populating rental products in product dimension
INSERT INTO Product_Dimension (ProductName, VendorID, Vendorname, Categoryname, categoryID,  ProductDailyRentalPrice, ProductWeeklyRental, ProductType,ProductId) 
SELECT p.productname, v.vendorid, v.vendorname , c.categoryname, c.categoryid, p.productpricedaily, p.productpriceweekly, "Rental", p.productid
FROM crnjakt_zagimore.rentalProducts p, crnjakt_zagimore.vendor v, crnjakt_zagimore.category c
WHERE p.categoryid = c.categoryid AND p.vendorid = v.vendorid;



--extracting facts from rental

--extracting fact in datastaging and creating temporary fact table 
-- only for weekly
DROP TABLE IntermediateFactTable;
CREATE TABLE IntermediateFactTable AS 
SELECT 0 AS UnitSolds, r.productpriceweekly * rv.duration AS RevenueGenerated, "RentalWeekly" AS RevenueType, rv.tid 
AS TID, r.productid AS produtId, c.customerid AS customerId, s.storeid AS storeId, rt.tdate AS fullDate 
FROM crnjakt_zagimore.rentalProducts r, crnjakt_zagimore.rentvia rv, 
crnjakt_zagimore.customer c, crnjakt_zagimore.store s, crnjakt_zagimore.rentaltransaction rt 
WHERE rv.productid = r.productid 
AND rv.tid=rt.tid 
AND c.customerid=rt.customerid 
AND s.storeid = rt.storeid
AND rv.rentaltype= 'W';

-- only for daily
INSERT INTO IntermediateFactTable (UnitSolds, RevenueGenerated, RevenueType, TID, produtId, customerId, storeId, fullDate)
SELECT 0 , r.productpricedaily * rv.duration , "RentalDaily", rv.tid, r.productid, c.customerid, s.storeid, rt.tdate 
FROM crnjakt_zagimore.rentalProducts r, crnjakt_zagimore.rentvia rv, 
crnjakt_zagimore.customer c, crnjakt_zagimore.store s, crnjakt_zagimore.rentaltransaction rt 
WHERE rv.productid = r.productid 
AND rv.tid=rt.tid 
AND c.customerid=rt.customerid 
AND s.storeid = rt.storeid
AND rv.rentaltype= 'D';


--insert into revenue
INSERT INTO Revenue (UnitSolds, RevenueGenerated,RevenueType, TID, CustomerKey,StoreKey, ProductKey, Calendar_Key)
SELECT i.UnitSolds , i.RevenueGenerated , i.RevenueType, i.TID, cd.CustomerKey , sd.StoreKey , pd.ProductKey , cad.Calendar_Key
FROM IntermediateFactTable as i , Customer_Dimension as cd, Store_Dimension as sd, Product_Dimension as pd, Calendar_Dimension cad
WHERE i.CustomerId = cd.CustomerId
AND sd.StoreId = i.StoreId
AND pd.ProductId = i.ProdutId 
AND pd.ProductType = 'RentalProduct'
AND cad.FullDate = i.FullDate;



--loading of dimension data from data staging into the data warehouse
INSERT INTO crnjakt_zagimore_dw.Customer_Dimension(CustomerKey,CName,CZip,CustomerId)
SELECT CustomerKey,CName,CZip,CustomerId 
FROM  Customer_Dimension;

INSERT INTO crnjakt_zagimore_dw.Store_Dimension(StoreKey,StoreId,StoreZip,RegioniD,RegionName)
SELECT StoreKey,StoreId,StoreZip,RegioniD,RegionName
FROM  Store_Dimension;

INSERT INTO crnjakt_zagimore_dw.Product_Dimension(ProductKey,	Productname,	VendorId,	Vendorname,	Categoryname,	categoryID,	ProductSalesPrice,	ProductDailyRentalPrice,	ProductWeeklyRental,	ProductType,	ProductId)
SELECT ProductKey,	Productname,	VendorId,	Vendorname,	Categoryname,	categoryID,	ProductSalesPrice,	ProductDailyRentalPrice,	ProductWeeklyRental,	ProductType,	ProductId
FROM  Product_Dimension;

INSERT INTO crnjakt_zagimore_dw.Calendar_Dimension(Calendar_Key,FullDate,MonthYear,Year)
SELECT Calendar_Key,FullDate,MonthYear,Year
FROM Calendar_Dimension

INSERT INTO crnjakt_zagimore_dw.Revenue (revenueGenerated, unitSolds, TID, revenueType, customerKey, storeKey, productKey, Calendar_Key)
SELECT revenueGenerated, unitSolds, TID, revenueType, customerKey, storeKey, productKey, Calendar_Key
FROM Revenue;
