CREATE TABLE Customer_Dimension (
  CustomerKey SERIAL PRIMARY KEY,
  CName VARCHAR(15) NOT NULL,
  CZip CHAR(5) NOT NULL,
  CustomerId CHAR(7) NOT NULL
);

CREATE TABLE Store_Dimension (
  StoreKey SERIAL PRIMARY KEY,
  StoreId VARCHAR(3) NOT NULL,
  StoreZip CHAR(5) NOT NULL,
  RegioniD CHAR(1) NOT NULL,
  RegionName VARCHAR(25) NOT NULL
);

CREATE TABLE Product_Dimension (
  ProductKey SERIAL PRIMARY KEY,
  Productname VARCHAR(25) NOT NULL,
  VendorId CHAR(2) NOT NULL,
  Vendorname VARCHAR(25) NOT NULL,
  Categoryname VARCHAR(25) NOT NULL,
  categoryID CHAR(2) NOT NULL,
  ProductSalesPrice DECIMAL(7,2),
  ProductDailyRentalPrice DECIMAL(7,2),
  ProductWeeklyRental DECIMAL(7,2),
  ProductType VARCHAR(10) NOT NULL,
  ProductId CHAR(3) NOT NULL
);

CREATE TABLE Calendar_Dimension (
  Calendar_Key SERIAL PRIMARY KEY,
  FullDate DATE NOT NULL,
  MonthYear INT,
  Year INT
);

CREATE TABLE Revenue (
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
