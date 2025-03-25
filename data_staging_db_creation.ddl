CREATE TABLE Customer_Dimension
(
  CustomerKey INT AUTO_INCREMENT,
  CName VARCHAR(15) NOT NULL,
  CZip CHAR(5) NOT NULL,
  CustomerId CHAR(7) NOT NULL,
  PRIMARY KEY (CustomerKey)
);

-- WILL HAVE TO BE LIKE THIS  
CREATE TABLE Customer_Dimension
(
  CustomerKey INTEGER PRIMARY KEY AUTOINCREMENT,
  CName VARCHAR(15) NOT NULL,
  CZip CHAR(5) NOT NULL,
  CustomerId CHAR(7) NOT NULL
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