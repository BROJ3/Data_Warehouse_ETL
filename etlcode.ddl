--extracting fact in datastaging and creating temporary fact table 
CREATE TABLE IntermediateFactTable AS --Only CREATE
SELECT sv.noofitems AS UnitSolds, p.productprice * sv.noofitems AS RevenueGenerated, "Sales" AS RevenueType, sv.tid 
AS TID, p.productid AS produtId, c.customerid AS customerId, s.storeid AS storeId, st.tdate AS fullDate 
FROM crnjakt_zagimore.product p, crnjakt_zagimore.soldvia sv, 
crnjakt_zagimore.customer c, crnjakt_zagimore.store s, crnjakt_zagimore.salestransaction st 
WHERE sv.productid = p.productid 
AND sv.tid=st.tid 
AND c.customerid=st.customerid 
AND s.storeid = st.storeid;

--populating fact table using intermediate fact table and joining the dimension
SELECT i.UnitSolds, i.RevenueGenerated, i.RevenueType, i.TID, cd.CustomerKey, sd.storeKey, pd.ProductKey
FROM IntermediateFactTable i, Customer_Dimension cd, Store_Dimension sd, Product_Dimension pd
WHERE i.CustomerId = cd.CustomerId AND i.CustomerId = cd.CustomerId AND sd.StoreId = i.storeId AND pd.ProductId=i.ProdutId AND pd.productType = "SalesProduct";

SELECT i.UnitSolds, i.RevenueGenerated, i.RevenueType, i.TID, cd.CustomerKey, sd.storeKey, pd.ProductKey, cad.Calendar_Key
FROM IntermediateFactTable i, Customer_Dimension cd, Store_Dimension sd, Product_Dimension pd, Calendar_Dimension cad
WHERE i.CustomerId = cd.CustomerId AND i.CustomerId = cd.CustomerId AND sd.StoreId = i.storeId AND pd.ProductId=i.ProdutId AND pd.productType = "SalesProduct";

--insert into revenue
INSERT INTO Revenue (UnitSolds, RevenueGenerated,RevenueType, TID, CustomerKey,StoreKey, ProductKey, Calendar_Key)
SELECT i.UnitSolds , i.RevenueGenerated , i.RevenueType, i.TID, cd.CustomerKey , sd.StoreKey , pd.ProductKey , cad.Calendar_Key
FROM IntermediateFactTable as i , Customer_Dimension as cd, Store_Dimension as sd, Product_Dimension as pd, Calendar_Dimension cad
WHERE i.CustomerId = cd.CustomerId
AND sd.StoreId = i.StoreId
AND pd.ProductId = i.ProdutId 
AND pd.ProductType = 'SalesProduct'
AND cad.FullDate = i.FullDate;



--creating some new data
INSERT INTO salestransaction VALUES ('ABC','1-2-333','S10','2025-03-25');
INSERT INTO `salestransaction` (`tid`, `customerid`, `storeid`, `tdate`) VALUES ('CDE', '6-7-888', 'S4', '2025-03-26');
INSERT INTO `soldvia` (`productid`, `tid`, `noofitems`) VALUES ('1X2', 'CDE', '3');
INSERT INTO `soldvia` (`productid`, `tid`, `noofitems`) VALUES ('1X3', 'CDE', '6');
INSERT INTO `rentaltransaction` (`tid`, `customerid`, `storeid`, `tdate`) VALUES ('FGH', '3-4-555', 'S7', '2025-03-26');
INSERT INTO `rentvia` (`productid`, `tid`, `rentaltype`, `duration`) 
VALUES ('1X1', 'FGH', 'D', '5');
INSERT INTO `rentvia` (`productid`, `tid`, `rentaltype`, `duration`) 
VALUES ('2X2', 'FGH', 'W', '6');
INSERT INTO `salestransaction` (`tid`, `customerid`, `storeid`, `tdate`) VALUES ('SOU', '6-7-888', 'S1', '2025-04-05');
INSERT INTO `soldvia` (`productid`, `tid`, `noofitems`) VALUES ('1X2', 'SOU', '5');
INSERT INTO `soldvia` (`productid`, `tid`, `noofitems`) VALUES ('1X3', 'SOU', '1');
INSERT INTO `rentaltransaction` (`tid`, `customerid`, `storeid`, `tdate`) VALUES ('CIC', '3-4-555', 'S4', '2025-04-23');
INSERT INTO `rentvia` (`productid`, `tid`, `rentaltype`, `duration`) 
VALUES ('1X1', 'CIC', 'D', '3');
INSERT INTO `rentvia` (`productid`, `tid`, `rentaltype`, `duration`) 
VALUES ('2X2', 'CIC', 'W', '2');
INSERT INTO `salestransaction` (`tid`, `customerid`, `storeid`, `tdate`) VALUES ('CDE', '6-7-888', 'S4', '2025-03-26');
INSERT INTO `soldvia` (`productid`, `tid`, `noofitems`) VALUES ('1X2', 'CDE', '3');
INSERT INTO `soldvia` (`productid`, `tid`, `noofitems`) VALUES ('1X3', 'CDE', '6');
INSERT INTO `rentaltransaction` (`tid`, `customerid`, `storeid`, `tdate`) VALUES ('FGH', '3-4-555', 'S7', '2025-03-26');
INSERT INTO `rentvia` (`productid`, `tid`, `rentaltype`, `duration`) 
VALUES ('1X1', 'FGH', 'D', '5');
INSERT INTO `rentvia` (`productid`, `tid`, `rentaltype`, `duration`) 
VALUES ('2X2', 'FGH', 'W', '6');

--create new salestransaction and rentaltransaciton
--created new TCR salestransactios
INSERT INTO `salestransaction` (`tid`, `customerid`, `storeid`, `tdate`) VALUES ('JOP', '6-7-888', 'S4', '2025-03-26');
INSERT INTO `soldvia` (`productid`, `tid`, `noofitems`) VALUES ('1X3', 'JOP', '3');
INSERT INTO `soldvia` (`productid`, `tid`, `noofitems`) VALUES ('1X2', 'JOP', '5');
INSERT INTO `rentaltransaction` (`tid`, `customerid`, `storeid`, `tdate`) VALUES ('BMD', '0-1-222', 'S8', '2025-03-27');
INSERT INTO `rentvia` (`productid`, `tid`, `rentaltype`, `duration`) VALUES ('5X5', 'BMD', 'D', '3');
INSERT INTO `rentvia` (`productid`, `tid`, `rentaltype`, `duration`) VALUES ('2X2', 'BMD', 'W', '3');

--if problems with Daily_Regular_Fact_Refresh extraction date you have 2 possibilities
UPDATE Revenue 
SET ExtractionTimestamp = ExtractionTimestamp - INTERVAL 1 DAY
WHERE Calendar_Key = 28468 AND Calendar_Key = 28469;

DELETE FROM Revenue WHERE Calendar_Key >= 28467;


--adding PDLoaded to customer
ALTER TABLE Customer_Dimension 
ADD ExtractionTimestamp TIMESTAMP,
ADD PDLoaded BOOLEAN;
UPDATE Customer_Dimension
SET ExtractionTimestamp = NOW() - INTERVAL 20 DAY;


--adding PDLoaded to store
ALTER TABLE Store_Dimension 
ADD ExtractionTimestamp TIMESTAMP,
ADD PDLoaded BOOLEAN;

UPDATE Store_Dimension
SET PDLoaded=True;
SET ExtractionTimestamp = NOW() - INTERVAL 20 DAY;

-- adding fdate valid form and until in data staging and data warehouse
ALTER TABLE Product_Dimension
ADD DVF DATE, ADD DVU DATE, ADD CurrentStatus CHAR(1);

UPDATE Product_Dimension SET DVF = '2013-01-01';
UPDATE Product_Dimension SET CurrentStatus = 'C';
UPDATE Product_Dimension SET DVU = '2040-01-01';

ALTER TABLE crnjakt_zagimore_dw.Product_Dimension
ADD DVF DATE, ADD DVU DATE, ADD CurrentStatus CHAR(1);

UPDATE crnjakt_zagimore_dw.Product_Dimension SET DVF = '2013-01-01';
UPDATE crnjakt_zagimore_dw.Product_Dimension SET CurrentStatus = 'C';
UPDATE crnjakt_zagimore_dw.Product_Dimension SET DVU = '2040-01-01';


--adding DVF,DVU,CurrentStatus for customer dimension
ALTER TABLE Customer_Dimension
ADD DVF DATE, ADD DVU DATE, ADD CurrentStatus CHAR(1);

UPDATE Customer_Dimension SET DVF = '2013-01-01';
UPDATE Customer_Dimension SET CurrentStatus = 'C';
UPDATE Customer_Dimension SET DVU = '2040-01-01';

ALTER TABLE crnjakt_zagimore_dw.Customer_Dimension
ADD DVF DATE, ADD DVU DATE, ADD CurrentStatus CHAR(1);

UPDATE crnjakt_zagimore_dw.Customer_Dimension SET DVF = '2013-01-01';
UPDATE crnjakt_zagimore_dw.Customer_Dimension SET CurrentStatus = 'C';
UPDATE crnjakt_zagimore_dw.Customer_Dimension SET DVU = '2040-01-01';

--adding for store
ALTER TABLE Store_Dimension
ADD DVF DATE, ADD DVU DATE, ADD CurrentStatus CHAR(1);

UPDATE Store_Dimension SET DVF = '2013-01-01';
UPDATE Store_Dimension SET CurrentStatus = 'C';
UPDATE Store_Dimension SET DVU = '2040-01-01';

ALTER TABLE crnjakt_zagimore_dw.Store_Dimension
ADD DVF DATE, ADD DVU DATE, ADD CurrentStatus CHAR(1);

UPDATE crnjakt_zagimore_dw.Store_Dimension SET DVF = '2013-01-01';
UPDATE crnjakt_zagimore_dw.Store_Dimension SET CurrentStatus = 'C';
UPDATE crnjakt_zagimore_dw.Store_Dimension SET DVU = '2040-01-01';


INSERT INTO `store` (`storeid`, `storezip`, `regionid`) VALUES ('s54', '67546', 'T');

--checking for changes in price
SELECT p.productname, p.productid, p.productprice, c.categoryname, v.vendorid, v.vendorname, c.categoryid, 'SalesProduct', NOW(), FALSE
FROM crnjakt_zagimore.product p, crnjakt_zagimore.category c, crnjakt_zagimore.vendor v, Product_Dimension pd
WHERE c.categoryid=p.categoryid AND p.vendorid = v.vendorid AND pd.productid = p.productid;

--change one of the prices
UPDATE `product` SET `productprice` = '70.00' WHERE `product`.`productid` = '1X4';


--code for type 2 refresh -> pre procedure
--check nonequal
SELECT p.productname, p.productid, p.productprice, pd.ProductSalesPrice
FROM crnjakt_zagimore.product p, crnjakt_zagimore.category c, crnjakt_zagimore.vendor v, Product_Dimension pd 
WHERE c.categoryid=p.categoryid 
AND p.vendorid=v.vendorid 
AND pd.productid=p.productid 
AND pd.ProductType='SalesProduct' 
AND p.productprice != pd.ProductSalesPrice

--finding ids of products taht changed their price
SELECT p.productid
FROM crnjakt_zagimore.product p, crnjakt_zagimore.category c, crnjakt_zagimore.vendor v, crnjakt_zagimore_ds.Product_Dimension pd 
WHERE c.categoryid=p.categoryid 
AND p.vendorid=v.vendorid 
AND pd.productid=p.productid 
AND pd.ProductType='SalesProduct' 
AND p.productprice != pd.ProductSalesPrice

-- INTERMEDIARY STEP: CREATE TABLE -OAOAOAOAOA
CREATE TABLE IPD AS
SELECT p.productid
FROM crnjakt_zagimore.product p, crnjakt_zagimore.category c, crnjakt_zagimore.vendor v, crnjakt_zagimore_ds.Product_Dimension pd 
WHERE c.categoryid=p.categoryid 
AND p.vendorid=v.vendorid 
AND pd.productid=p.productid 
AND pd.ProductType='SalesProduct' 
AND p.productprice != pd.ProductSalesPrice

--after finding, updating DVU of products woose price has changed
UPDATE Product_Dimension SET DVU = DATE(NOW() - INTERVAL 1 DAY), CurrentStatus = 'N'
WHERE ProductId IN (SELECT ProductId FROM IPD);


-- insert into product dimension
INSERT INTO Product_Dimension (ProductId, Productname, ProductSalesPrice, VendorId, Vendorname, categoryID, Categoryname, ProductType, ExtractionTimestamp, PDLoaded, DVF, DVU, CurrentStatus)
SELECT p.productid, p.productname , p.productprice, v.vendorid, v.vendorname ,c.categoryid, c.categoryname , 'SalesProduct', NOW(), False, NOW(), '2040-01-01', 'C'
FROM  crnjakt_zagimore.product as p , crnjakt_zagimore.category as c, crnjakt_zagimore.vendor as v 
WHERE c.categoryid = p.categoryid and p.vendorid = v.vendorid
AND p.productid in (SELECT * FROM IPD);


--almost --problem is that replace into deletes a duplicate vaue which is refereneced in "revenue"
Replace INTO crnjakt_zagimore_dw.Product_Dimension (ProductKey, ProductId, Productname, ProductSalesPrice, ProductDailyRentalPrice, ProductWeeklyRental,VendorId, Vendorname, categoryID, Categoryname, ProductType , dvf , dvu , currentstatus)
SELECT ProductKey, ProductId, Productname, ProductSalesPrice,ProductDailyRentalPrice, ProductWeeklyRental, VendorId, Vendorname, categoryID, Categoryname, ProductType , dvf , dvu , currentstatus --'C'
from Product_Dimension; 


--class april 10 -> testing the code
UPDATE Product_Dimension
SET PDLoaded = TRUE  
WHERE PDLoaded = FALSE;


--something in april 10 class at 25min in
UPDATE `product` SET `productname` = 'Solar Charger' WHERE `product`.`productid` = '1X3'
UPDATE `product` SET `productprice` = 44.00 WHERE `product`.`productid` = '1Z1'

--taken from line 854
SELECT p.productid
FROM crnjakt_zagimore.product p, crnjakt_zagimore.category c, crnjakt_zagimore.vendor v, crnjakt_zagimore_ds.Product_Dimension pd 
WHERE c.categoryid=p.categoryid 
AND p.vendorid=v.vendorid 
AND pd.productid=p.productid 
AND pd.ProductType='SalesProduct' 
AND (p.productprice != pd.ProductSalesPrice OR p.productName != pd.productName)
AND pd.CurrentStatus = 'C'

--ANOTHER IPD
DROP TABLE IPD
CREATE TABLE IPD AS
SELECT p.productid
FROM crnjakt_zagimore.product p, crnjakt_zagimore.category c, crnjakt_zagimore.vendor v, crnjakt_zagimore_ds.Product_Dimension pd 
WHERE c.categoryid=p.categoryid 
AND p.vendorid=v.vendorid 
AND pd.productid=p.productid 
AND pd.ProductType='SalesProduct' 
AND p.productprice != pd.ProductSalesPrice

--same as earlier
UPDATE Product_Dimension SET DVU = DATE(NOW() - INTERVAL 1 DAY), CurrentStatus = 'N'
WHERE ProductId IN (SELECT ProductId FROM IPD);

--same as earlier
Replace INTO crnjakt_zagimore_dw.Product_Dimension (ProductKey, ProductId, Productname, ProductSalesPrice, ProductDailyRentalPrice, ProductWeeklyRental,VendorId, Vendorname, categoryID, Categoryname, ProductType , dvf , dvu , currentstatus)
SELECT ProductKey, ProductId, Productname, ProductSalesPrice,ProductDailyRentalPrice, ProductWeeklyRental, VendorId, Vendorname, categoryID, Categoryname, ProductType , dvf , dvu , currentstatus
from Product_Dimension; 

















SELECT COUNT(*) FROM crnjakt_zagimore_ds.Product_Dimension WHERE CurrentStatus = 'C'
UNION
SELECT COUNT(*) FROM crnjakt_zagimore.product
UNION
SELECT COUNT(*) FROM crnjakt_zagimore.rentalProducts;

SELECT (SELECT COUNT(*) FROM crnjakt_zagimore_ds.Product_Dimension WHERE CurrentStatus = 'C')
-
(SELECT COUNT(*) FROM crnjakt_zagimore.product)
-
(SELECT COUNT(*) FROM crnjakt_zagimore.rentalProducts);




UPDATE `product` SET `productprice` = '70.00' WHERE `product`.`productid` = '1X4';
UPDATE `product` SET `productname` = 'Solar Charger' WHERE `product`.`productid` = '1X3';
UPDATE `product` SET `productprice` = 44.00 WHERE `product`.`productid` = '1Z1';



--latefactrefresh -- not selecting rentals - reran everything and works




--daily regular fact refresh



-- DATA that has been changed
UPDATE `product` SET `productprice` = '70.00' WHERE `product`.`productid` = '1X4';
UPDATE `product` SET `productname` = 'Solar Charger' WHERE `product`.`productid` = '1X3';
UPDATE `product` SET `productprice` = 44.00 WHERE `product`.`productid` = '1Z1';


--type 2 changes








END


-- prvo izmijeni data
UPDATE `store` SET `storezip` = '11000' WHERE `store`.`storeid` = 'S10';
UPDATE `store` SET `storezip` = '15000' WHERE `store`.`storeid` = 'S5';
UPDATE `store` SET `storezip` = '60001' WHERE `store`.`storeid` = 'S12';
UPDATE `store` SET `storezip` = '70001' WHERE `store`.`storeid` = 'S13';









SELECT COUNT(*) FROM crnjakt_zagimore_ds.Product_Dimension WHERE CurrentStatus = 'C'
UNION
SELECT COUNT(*) FROM crnjakt_zagimore.product
UNION
SELECT COUNT(*) FROM crnjakt_zagimore.rentalProducts;


SELECT (SELECT COUNT(*) FROM crnjakt_zagimore_ds.Product_Dimension WHERE CurrentStatus = 'C')
-
(SELECT COUNT(*) FROM crnjakt_zagimore.product)
-
(SELECT COUNT(*) FROM crnjakt_zagimore.rentalProducts);


--final test 
--add more values

INSERT INTO vendor VALUES('PM','Pemo Trade');
INSERT INTO vendor VALUES('KM','Kerum Market');

INSERT INTO category VALUES('SP','Sun Products');
INSERT INTO category VALUES('FF','Flipflops');

INSERT INTO product VALUES('9x2','Crocks',30,'KM','FF');
INSERT INTO product VALUES('9x7','SPFifty',20,'PM','SP');

INSERT INTO store VALUES('S22','20000','N');
INSERT INTO store VALUES('S23','20001','N');
 
INSERT INTO customer VALUES('9-8-222','Tana','01350');
INSERT INTO customer VALUES('1-1-111','Maja','99876');

INSERT INTO salestransaction VALUES ('T121','1-1-111','S22','2013-01-01');
INSERT INTO salestransaction VALUES ('T774','9-8-222','S23','2024-04-23');

INSERT INTO soldvia VALUES('9X9','T121',1);
INSERT INTO soldvia VALUES('9X7','T774',1);


INSERT INTO rentalProducts(productid, productname, productpricedaily, productpriceweekly, vendorid, categoryid) VALUES ('7X5','Guitar',15, 50,'KM','SP');
INSERT INTO rentalProducts(productid, productname, productpricedaily, productpriceweekly, vendorid, categoryid) VALUES ('5X7','Canvas',20, 80,'PM','EL');
 
INSERT INTO rentaltransaction(tid, customerid, storeid, tdate) VALUES('339','1-1-111','S5','2019-01-16');
INSERT INTO rentaltransaction(tid, customerid, storeid, tdate) VALUES('338','9-8-222','S5','2024-04-23');

INSERT INTO rentvia(productid, tid, rentaltype, duration) VALUES ('7X5','339','D',2);
INSERT INTO rentvia(productid, tid, rentaltype, duration) VALUES ('5X7','338','W',2);

-- all added, all in database :))

