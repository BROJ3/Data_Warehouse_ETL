
CREATE TABLE productCategoryDimension AS
SELECT DISTINCT p.categoryId, p.categoryName 
FROM Product_Dimension p

ALTER TABLE productCategoryDimension
ADD COLUMN ProductCategoryKey INT AUTO_INCREMENT PRIMARY KEY

-- selecting for aggregate
SELECT SUM(r.UnitSolds) AS TotalUnitSold, SUM(r.RevenueGenerated) AS TotalRevenueGenerated, r.Calendar_Key, r.CustomerKey, r.StoreKey, pcd.ProductCategoryKey 
FROM Revenue AS r, productCategoryDimension AS pcd, Product_Dimension AS pd 
WHERE r.ProductKey = pd.ProductKey AND pcd.categoryID = pd.categoryID 
GROUP BY r.Calendar_Key, r.CustomerKey, r.StoreKey, pcd.ProductCategoryKey;

--creating the aggregate
CREATE TABLE OneWayRevenueAggregateByProduct AS
SELECT SUM(r.UnitSolds) AS TotalUnitSold, SUM(r.RevenueGenerated) AS TotalRevenueGenerated, r.Calendar_Key, r.CustomerKey, r.StoreKey, pcd.ProductCategoryKey 
FROM Revenue AS r, productCategoryDimension AS pcd, Product_Dimension AS pd 
WHERE r.ProductKey = pd.ProductKey AND pcd.categoryID = pd.categoryID 
GROUP BY r.Calendar_Key, r.CustomerKey, r.StoreKey, pcd.ProductCategoryKey;

--define primary key in the aggregate
ALTER TABLE `OneWayRevenueAggregateByProduct` 
ADD PRIMARY KEY(`Calendar_Key`, `CustomerKey`, `StoreKey`, `ProductCategoryKey`);


CREATE TABLE crnjakt_zagimore_dw.ProductCategoryDimension AS
SELECT * FROM productCategoryDimension
ALTER TABLE `ProductCategoryDimension` ADD PRIMARY KEY(`ProductCategoryKey`);

CREATE TABLE crnjakt_zagimore_dw.OneWayAggregateByProductCategory AS
SELECT * FROM OneWayRevenueAggregateByProduct
ALTER TABLE `OneWayAggregateByProductCategory` 
ADD PRIMARY KEY(`Calendar_Key`, `CustomerKey`, `StoreKey`, `ProductCategoryKey`);

ALTER TABLE crnjakt_zagimore_dw.OneWayAggregateByProductCategory
ADD Foreign Key (Calendar_Key) 
REFERENCES crnjakt_zagimore_dw.Calendar_Dimension(Calendar_Key);

ALTER TABLE crnjakt_zagimore_dw.OneWayAggregateByProductCategory
ADD FOREIGN KEY(CustomerKey) 
REFERENCES crnjakt_zagimore_dw.Customer_Dimension(CustomerKey),
ADD FOREIGN KEY(StoreKey)
REFERENCES crnjakt_zagimore_dw.Store_Dimension(StoreKey),
ADD FOREIGN KEY(ProductCategoryKey)
REFERENCES crnjakt_zagimore_dw.ProductCategoryDimension(ProductCategoryKey)


--another snapshot starts here -- snapshot by store
CREATE TABLE DailyStoreSnapshot AS
SELECT SUM(r.UnitSolds) AS TotalUnitSold, SUM(r.RevenueGenerated) AS TotalRevenueGenerated, AVG(RevenueGenerated) AS AverageRevenueGenerated, r.Calendar_Key, r.StoreKey, COUNT(DISTINCT r.TID) AS TotalNumOfTransactions
FROM Revenue AS r
GROUP BY r.Calendar_Key, r.StoreKey;

--changing the data type to standardize 
ALTER TABLE `DailyStoreSnapshot` 
CHANGE `AverageREvenueGenerated` `AverageRevenueGenerated` DECIMAL(10,2)
--or more elegant way
ALTER TABLE `DailyStoreSnapshot` 
MODIFY COLUMN `AverageRevenueGenerated` DECIMAL(9,2)



--create table FootwearRevenue
CREATE TABLE FootwearRevenue AS
SELECT SUM(r.RevenueGenerated) AS TotalFootwearRevenue, r.Calendar_Key, r.StoreKey
FROM Revenue AS r, Product_Dimension AS pd
WHERE pd.Categoryname = "Footwear" AND r.ProductKey = pd.ProductKey
GROUP BY r.Calendar_Key, r.StoreKey;

--adding a column "TotalFootwearRevenue" to the snapshot
ALTER TABLE DailyStoreSnapshot
ADD COLUMN TotalFootwearRevenue INT DEFAULT 0

--updating "TotalFootwearRevenue" values in the DailyStoreSnapshot
UPDATE DailyStoreSnapshot ds, FootwearRevenue fw
SET ds.TotalFootwearRevenue = fw.TotalFootwearRevenue
WHERE ds.Calendar_Key = fw.Calendar_Key
AND ds.StoreKey = fw.StoreKey

--adding nother column - NumberofHighValueTransactions
ALTER TABLE DailyStoreSnapshot
ADD COLUMN NumberofHVTransactions INT DEFAULT 0

--create temporary table
CREATE TABLE HVTransactionCount AS
SELECT COUNT(DISTINCT r.TID)AS TransactionCount, r.Calendar_Key, r.StoreKey
FROM Revenue r
WHERE r.RevenueGenerated > 100
GROUP BY StoreKey, Calendar_Key;


ALTER TABLE DailyStoreSnapshot
ADD COLUMN TotlLocalRevenue INT DEFAULT 0

CREATE TABLE TotalLocalRevenue AS
SELECT SUM(r.RevenueGenerated) AS TotalLocalRevenue, r.Calendar_Key, r.StoreKey
FROM Revenue AS r, Store_Dimension AS sd, Customer_Dimension AS cd
WHERE LEFT(sd.StoreZip,2) = LEFT(cd.CZip,2) 
AND sd.StoreKey = r.StoreKey AND cd.CustomerKey = r.CustomerKey
GROUP BY r.Calendar_Key, r.StoreKey;


UPDATE DailyStoreSnapshot ds, TotalLocalRevenue lr
SET ds.TotlLocalRevenue = lr.TotalLocalRevenue
WHERE ds.Calendar_Key = lr.Calendar_Key
AND ds.StoreKey = lr.StoreKey


UPDATE DailyStoreSnapshot ds, HVTransactionCount hv
SET ds.numberofHVTransactions = hv.TransactionCount
WHERE ds.Calendar_Key = hv.Calendar_Key
AND ds.StoreKey = hv.StoreKey

DROP TABLE TotalLocalRevenue,FootwearRevenue;
DROP TABLE HVTransactionCount;


--copying snapshot into DW
CREATE TABLE crnjakt_zagimore_dw.DailyStoreSnapshot AS
SELECT * FROM DailyStoreSnapshot

--give it a primary key
ALTER TABLE crnjakt_zagimore_dw.DailyStoreSnapshot
ADD PRIMARY KEY(Calendar_Key,StoreKey)

ALTER TABLE crnjakt_zagimore_dw.DailyStoreSnapshot 
ADD Foreign Key(Calendar_Key) REFERENCES 
crnjakt_zagimore_dw.Calendar_Dimension(Calendar_Key);

ALTER TABLE crnjakt_zagimore_dw.DailyStoreSnapshot 
ADD Foreign Key(StoreKey) REFERENCES 
crnjakt_zagimore_dw.Store_Dimension(StoreKey);


ALTER TABLE Revenue
ADD COLUMN ExtractionTimestamp TIMESTAMP, ADD f_loaded BOOLEAN

UPDATE Revenue
SET ExtractionTimestamp = NOW() - INTERVAL 10 DAY

UPDATE Revenue
SET f_loaded = True